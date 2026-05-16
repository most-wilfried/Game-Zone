class AppSettings {
  final int id;
  final double basePrice;
  final int baseMinutes;
  final bool ttsEnabled;
  final String voiceGender;
  final int bonusGiftMinutes;

  const AppSettings({
    this.id = 1,
    required this.basePrice,
    required this.baseMinutes,
    this.ttsEnabled = true,
    this.voiceGender = 'female',
    this.bonusGiftMinutes = 40,
  });

  AppSettings copyWith({
    int? id,
    double? basePrice,
    int? baseMinutes,
    bool? ttsEnabled,
    String? voiceGender,
    int? bonusGiftMinutes,
  }) {
    return AppSettings(
      id: id ?? this.id,
      basePrice: basePrice ?? this.basePrice,
      baseMinutes: baseMinutes ?? this.baseMinutes,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      voiceGender: voiceGender ?? this.voiceGender,
      bonusGiftMinutes: bonusGiftMinutes ?? this.bonusGiftMinutes,
    );
  }

  double priceToMinutes(double price) {
    if (price <= 0 || basePrice <= 0 || baseMinutes <= 0) return 0;
    return (price / basePrice) * baseMinutes;
  }

  double minutesToPrice(int minutes) {
    if (minutes <= 0 || baseMinutes <= 0) return 0;
    return (minutes / baseMinutes) * basePrice;
  }

  String get ratioLabel =>
      '${basePrice.toStringAsFixed(0)} FCFA = $baseMinutes min';

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      id: map['id'] as int? ?? 1,
      basePrice: (map['base_price'] as num).toDouble(),
      baseMinutes: map['base_minutes'] as int,
      ttsEnabled: (map['tts_enabled'] as int? ?? 1) == 1,
      voiceGender: map['voice_gender'] as String? ?? 'female',
      bonusGiftMinutes: map['bonus_gift_minutes'] as int? ?? 40,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'base_price': basePrice,
      'base_minutes': baseMinutes,
      'tts_enabled': ttsEnabled ? 1 : 0,
      'voice_gender': voiceGender,
      'bonus_gift_minutes': bonusGiftMinutes,
    };
  }
}
