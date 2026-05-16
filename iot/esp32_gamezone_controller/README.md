# GameZone ESP32 Controller

Ce dossier contient le sketch Arduino a televerser dans l'ESP32 pour piloter 4 relais et afficher l'etat des 4 postes sur un TFT SPI 2.4 pouces 240x320.

## Bibliotheques Arduino IDE

Installe ces bibliotheques depuis le Library Manager:

- `Firebase ESP Client` by Mobizt
- `Adafruit GFX Library`
- `Adafruit ILI9341`

## Broches proposees

### TFT SPI 2.4 pouces ILI9341

| TFT | ESP32 |
| --- | --- |
| VCC | 3V3 |
| GND | GND |
| SCK / CLK | GPIO18 |
| MOSI / SDI | GPIO23 |
| MISO / SDO | GPIO19 |
| CS | GPIO5 |
| DC / A0 | GPIO16 |
| RESET / RST | GPIO17 |
| LED / BL | GPIO4 |

### Relais

| Relais | Poste | ESP32 |
| --- | --- | --- |
| IN1 | Poste 1 | GPIO25 |
| IN2 | Poste 2 | GPIO26 |
| IN3 | Poste 3 | GPIO27 |
| IN4 | Poste 4 | GPIO32 |
| VCC | Alimentation relais | 5V selon module |
| GND | Masse commune | GND ESP32 |

Important: garde une masse commune entre ESP32 et module relais. Si ton module relais est actif a HIGH, mets `RELAY_ACTIVE_LOW` a `false` dans le sketch.

## Chemins Firebase utilises

Le sketch lit:

- `/esp32_devices/station_1`
- `/esp32_devices/station_2`
- `/esp32_devices/station_3`
- `/esp32_devices/station_4`

L'application Flutter ecrit deja:

- `state: "occupe"` quand un poste est active
- `command: "power_on"` quand un poste doit s'allumer
- `state: "libre"` et `command: "power_off"` quand un poste doit s'eteindre

Le sketch affiche un carreau par poste:

- vert: poste active / relais ON
- rouge: poste desactive / relais OFF
- orange: poste en pause
- gris: maintenance

## Avant televersement

Dans `esp32_gamezone_controller.ino`, remplace:

```cpp
#define WIFI_SSID "NOM_DE_TON_WIFI"
#define WIFI_PASSWORD "MOT_DE_PASSE_WIFI"
```

Selectionne dans Arduino IDE:

- Board: `ESP32 Dev Module`
- Upload Speed: `921600` ou `115200` si le televersement echoue
- Port: le port USB de ton ESP32

Ouvre le Serial Monitor a `115200` bauds pour voir la connexion Wi-Fi/Firebase.
