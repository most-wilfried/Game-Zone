import 'package:flutter/material.dart';

class AppConstants {
  // Conversion 250 FCFA = 40 minutes
  static const double basePrice = 250.0;
  static const int baseMinutes = 40;

  // Statuts
  static const String statusLibre = 'libre';
  static const String statusOccupe = 'occupe';
  static const String statusEnPause = 'en_pause';
  static const String statusMaintenance = 'maintenance';

  // Couleurs par statut
  static const Map<String, Color> statusColors = {
    statusLibre: Color(0xFF10B981), // Vert
    statusOccupe: Color(0xFFEF4444), // Rouge
    statusEnPause: Color(0xFFF59E0B), // Orange
    statusMaintenance: Color(0xFF6B7280), // Gris
  };

  // Labels
  static const Map<String, String> statusLabels = {
    statusLibre: 'Libre',
    statusOccupe: 'Occupé',
    statusEnPause: 'En pause',
    statusMaintenance: 'Maintenance',
  };

  // Abréviations consoles ASCII pour éviter les soucis de police.
  static const Map<String, String> consoleEmojis = {
    'PlayStation 5': 'PS5',
    'PS5 Standard': 'PS5',
    'PS5 Slim': 'PS5',
    'PS5 Digital': 'PS5',
    'PS5 Pro': 'PS5',
    'PlayStation 4': 'PS4',
    'PS4 Standard': 'PS4',
    'PS4 Slim': 'PS4',
    'PS4 Pro': 'PS4',
    'PlayStation 3': 'PS3',
    'PS3 Slim': 'PS3',
    'PS5': 'PS',
    'PS4': 'PS',
    'Xbox Series X': 'XB',
    'Xbox Series S': 'XB',
    'Xbox One': 'XB',
    'Xbox One S': 'XB',
    'Xbox One X': 'XB',
    'Xbox 360': '360',
    'Nintendo Switch OLED': 'SW',
    'Nintendo Switch Lite': 'SW',
    'Nintendo Switch 2': 'SW',
    'Nintendo Switch': 'SW',
    'PC Gaming': 'PC',
    'PC Gamer': 'PC',
    'PC Gamer Mini': 'PC',
  };

  static const List<String> consoleTypes = [
    'PS5 Standard',
    'PS5 Slim',
    'PS5 Digital',
    'PS5 Pro',
    'PS4 Standard',
    'PS4 Slim',
    'PS4 Pro',
    'PS3 Slim',
    'Xbox Series X',
    'Xbox Series S',
    'Xbox One',
    'Xbox One S',
    'Xbox One X',
    'Xbox 360',
    'Nintendo Switch',
    'Nintendo Switch OLED',
    'Nintendo Switch Lite',
    'Nintendo Switch 2',
    'PC Gaming',
    'PC Gamer Mini',
  ];

  static const List<String> inventoryTypes = [
    'Console',
    'Manette',
    'Casque audio',
    'Casque VR',
    'Écran',
    'Câble',
    'Chargeur',
    'Support',
    'Stockage',
    'Autre',
  ];

  static const Map<String, List<String>> inventoryModelsByType = {
    'Console': consoleTypes,
    'Manette': [
      'DualSense PS5',
      'DualShock 4 PS4',
      'Manette PS3',
      'Xbox Series Controller',
      'Xbox One Controller',
      'Xbox 360 Controller',
      'Nintendo Switch Joy-Con',
      'Nintendo Switch Pro Controller',
      'Manette PC',
    ],
    'Casque audio': [
      'Casque filaire',
      'Casque Bluetooth',
      'Casque gaming USB',
      'Casque gaming jack 3.5',
    ],
    'Casque VR': [
      'PlayStation VR',
      'PlayStation VR2',
      'Meta Quest 2',
      'Meta Quest 3',
    ],
    'Écran': [
      'Écran 24 pouces',
      'Écran 27 pouces',
      'TV 32 pouces',
      'TV 43 pouces',
      'TV 55 pouces',
    ],
    'Câble': ['HDMI', 'USB-C', 'Micro USB', 'Alimentation console', 'Ethernet'],
    'Chargeur': [
      'Station charge DualSense',
      'Station charge Xbox',
      'Chargeur Joy-Con',
      'Chargeur USB-C',
    ],
    'Support': ['Support console', 'Support casque', 'Support manette'],
    'Stockage': ['SSD externe', 'Disque dur externe', 'Carte microSD'],
    'Autre': ['Accessoire divers'],
  };

  static List<String> inventoryModelsFor(String type) {
    return inventoryModelsByType[type] ?? const ['Accessoire divers'];
  }

  // Conversion prix → minutes
  static double priceToMinutes(double price) {
    if (price <= 0) return 0;
    return (price / basePrice) * baseMinutes;
  }

  // Conversion minutes → prix
  static double minutesToPrice(int minutes) {
    if (minutes <= 0) return 0;
    return (minutes / baseMinutes) * basePrice;
  }

  // Format durée
  static String formatDuration(int minutes) {
    if (minutes < 0) return '00:00';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}h${mins.toString().padLeft(2, '0')}';
    }
    return '${mins}min';
  }

  // Format prix
  static String formatPrice(double price) {
    return '${price.toStringAsFixed(0)} FCFA';
  }
}
