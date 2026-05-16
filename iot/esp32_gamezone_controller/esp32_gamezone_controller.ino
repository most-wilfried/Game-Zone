/*
  GameZone ESP32 Controller

  Materiel cible:
  - ESP32 DevKit
  - Ecran TFT SPI 2.4 pouces 240x320, controleur ILI9341
  - Module 4 relais

  Bibliotheques Arduino IDE a installer:
  - Firebase ESP Client by Mobizt
  - Adafruit GFX Library
  - Adafruit ILI9341

  Chemin Firebase lu:
  /esp32_devices/station_1
  /esp32_devices/station_2
  /esp32_devices/station_3
  /esp32_devices/station_4

  Etats attendus depuis l'application:
  - state = "occupe" -> relais ON, carreau vert
  - state = "libre" / "en_pause" / "maintenance" -> relais OFF, carreau rouge/orange/gris
*/

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include <time.h>

#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"

// A remplacer avant le televersement.
#define WIFI_SSID "AQUOS sense3 plus"
#define WIFI_PASSWORD "123456789"

// Projet Firebase GameZone.
#define API_KEY "AIzaSyC5-sa_qW139kS6q3yBgdqmmQSQIgoRxr8"
#define DATABASE_URL "https://gamezone-108f6-default-rtdb.europe-west1.firebasedatabase.app"

// Compte autorise par les regles Firebase actuelles.
#define USER_EMAIL "admin@gmail.com"
#define USER_PASSWORD "admin123"

// TFT ILI9341 sur bus VSPI de l'ESP32.
// SCK = GPIO18, MOSI = GPIO23, MISO = GPIO19.
#define TFT_CS 5
#define TFT_DC 16
#define TFT_RST 17
#define TFT_BL 4

// Relais. La plupart des modules relais sont actifs a LOW.
// Mets RELAY_ACTIVE_LOW a false si ton module s'active avec HIGH.
const bool RELAY_ACTIVE_LOW = true;
const int RELAY_PINS[4] = {25, 26, 27, 32};

const int STATION_IDS[4] = {1, 2, 3, 4};
const char* DEFAULT_NAMES[4] = {"Poste 1", "Poste 2", "Poste 3", "Poste 4"};

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
Adafruit_ILI9341 tft(TFT_CS, TFT_DC, TFT_RST);

struct StationState {
  String name;
  String state;
  String command;
  bool relayOn;
};

StationState stations[4];
unsigned long lastPollAt = 0;
unsigned long lastHeartbeatAt = 0;
bool screenDirty = true;

void setup() {
  Serial.begin(115200);
  delay(300);

  setupRelays();
  setupScreen();
  connectWifi();
  setupFirebase();
  initStationState();

  drawDashboard("Connexion Firebase...");
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWifi();
    screenDirty = true;
  }

  if (Firebase.ready()) {
    const unsigned long now = millis();
    if (now - lastPollAt >= 300) {
      lastPollAt = now;
      readStationsFromFirebase();
    }

    if (now - lastHeartbeatAt >= 15000) {
      lastHeartbeatAt = now;
      sendHeartbeat();
    }
  }

  if (screenDirty) {
    drawDashboard(Firebase.ready() ? "Synchronise avec GameZone" : "Firebase hors ligne");
    screenDirty = false;
  }
}

void setupRelays() {
  for (int i = 0; i < 4; i++) {
    pinMode(RELAY_PINS[i], OUTPUT);
    setRelay(i, false);
  }
}

void setupScreen() {
  pinMode(TFT_BL, OUTPUT);
  digitalWrite(TFT_BL, HIGH);
  tft.begin();
  tft.setRotation(1); // 320 x 240, paysage.
  tft.fillScreen(ILI9341_BLACK);
  tft.setTextWrap(false);
}

void connectWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  tft.fillScreen(ILI9341_BLACK);
  tft.setCursor(16, 24);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.print("GameZone IoT");
  tft.setCursor(16, 58);
  tft.setTextSize(1);
  tft.print("Connexion WiFi...");

  unsigned long startedAt = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startedAt < 20000) {
    delay(300);
    Serial.print(".");
  }

  Serial.println();
  Serial.print("WiFi: ");
  Serial.println(WiFi.status() == WL_CONNECTED ? WiFi.localIP().toString() : "echec");
}

void setupFirebase() {
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.token_status_callback = tokenStatusCallback;

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void initStationState() {
  for (int i = 0; i < 4; i++) {
    stations[i].name = DEFAULT_NAMES[i];
    stations[i].state = "libre";
    stations[i].command = "idle";
    stations[i].relayOn = false;
  }
}

void readStationsFromFirebase() {
  if (!Firebase.RTDB.getJSON(&fbdo, "/esp32_devices")) {
    Serial.print("Lecture impossible /esp32_devices: ");
    Serial.println(fbdo.errorReason());
    return;
  }

  FirebaseJson* json = fbdo.to<FirebaseJson*>();

  for (int i = 0; i < 4; i++) {
    FirebaseJsonData data;
    String basePath = "station_" + String(STATION_IDS[i]) + "/";

    String nextName = DEFAULT_NAMES[i];
    String nextState = "libre";
    String nextCommand = "idle";

    if (json->get(data, basePath + "station_name") && data.type == "string") {
      nextName = data.stringValue;
    }
    if (json->get(data, basePath + "state") && data.type == "string") {
      nextState = data.stringValue;
    }
    if (json->get(data, basePath + "command") && data.type == "string") {
      nextCommand = data.stringValue;
    }

    bool nextRelayOn = nextState == "occupe" || nextCommand == "power_on";
    if (nextState == "libre" || nextCommand == "power_off") {
      nextRelayOn = false;
    }

    if (
      stations[i].name != nextName ||
      stations[i].state != nextState ||
      stations[i].command != nextCommand ||
      stations[i].relayOn != nextRelayOn
    ) {
      stations[i].name = nextName;
      stations[i].state = nextState;
      stations[i].command = nextCommand;
      stations[i].relayOn = nextRelayOn;
      setRelay(i, nextRelayOn);
      screenDirty = true;
    }
  }
}

void sendHeartbeat() {
  String isoNow = isoTimestamp();
  for (int i = 0; i < 4; i++) {
    String path = "/esp32_devices/station_" + String(STATION_IDS[i]) + "/last_seen_at";
    Firebase.RTDB.setString(&fbdo, path.c_str(), isoNow);
  }
}

void setRelay(int index, bool enabled) {
  const int level = RELAY_ACTIVE_LOW
    ? (enabled ? LOW : HIGH)
    : (enabled ? HIGH : LOW);
  digitalWrite(RELAY_PINS[index], level);
}

void drawDashboard(const char* message) {
  tft.fillScreen(ILI9341_BLACK);
  drawHeader(message);

  const int cardW = 145;
  const int cardH = 78;
  const int gap = 12;
  const int startX = 12;
  const int startY = 62;

  for (int i = 0; i < 4; i++) {
    int col = i % 2;
    int row = i / 2;
    int x = startX + col * (cardW + gap);
    int y = startY + row * (cardH + gap);
    drawStationCard(i, x, y, cardW, cardH);
  }
}

void drawHeader(const char* message) {
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setCursor(12, 10);
  tft.print("GameZone");

  tft.setTextSize(1);
  tft.setCursor(12, 34);
  tft.setTextColor(WiFi.status() == WL_CONNECTED ? ILI9341_GREEN : ILI9341_RED);
  tft.print(WiFi.status() == WL_CONNECTED ? "WiFi OK" : "WiFi OFF");

  tft.setCursor(82, 34);
  tft.setTextColor(Firebase.ready() ? ILI9341_GREEN : ILI9341_ORANGE);
  tft.print(Firebase.ready() ? "Firebase OK" : "Firebase...");

  tft.setCursor(190, 34);
  tft.setTextColor(ILI9341_LIGHTGREY);
  tft.print(message);
}

void drawStationCard(int index, int x, int y, int w, int h) {
  uint16_t color = colorForState(stations[index].state, stations[index].relayOn);
  uint16_t fill = stations[index].relayOn ? 0x0320 : 0x1800;

  tft.fillRoundRect(x, y, w, h, 8, fill);
  tft.drawRoundRect(x, y, w, h, 8, color);
  tft.drawRoundRect(x + 1, y + 1, w - 2, h - 2, 8, color);

  tft.setTextSize(2);
  tft.setTextColor(ILI9341_WHITE);
  tft.setCursor(x + 10, y + 12);
  tft.print(stations[index].name);

  tft.setTextSize(1);
  tft.setCursor(x + 10, y + 42);
  tft.setTextColor(color);
  tft.print(labelForState(stations[index].state, stations[index].relayOn));

  tft.setCursor(x + 10, y + 58);
  tft.setTextColor(ILI9341_LIGHTGREY);
  tft.print("Relais GPIO ");
  tft.print(RELAY_PINS[index]);
}

uint16_t colorForState(const String& state, bool relayOn) {
  if (relayOn || state == "occupe") return ILI9341_GREEN;
  if (state == "en_pause") return ILI9341_ORANGE;
  if (state == "maintenance") return ILI9341_DARKGREY;
  return ILI9341_RED;
}

const char* labelForState(const String& state, bool relayOn) {
  if (relayOn || state == "occupe") return "ACTIVE";
  if (state == "en_pause") return "EN PAUSE";
  if (state == "maintenance") return "MAINT.";
  return "DESACTIVE";
}

String isoTimestamp() {
  time_t now;
  time(&now);
  if (now < 100000) {
    return String(millis());
  }

  struct tm timeinfo;
  gmtime_r(&now, &timeinfo);
  char buffer[25];
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
  return String(buffer);
}
