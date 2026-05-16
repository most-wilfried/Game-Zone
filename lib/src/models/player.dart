class Player {
  final int? id;
  final String name;
  final int totalSessions;
  final double totalSpent;
  final int totalMinutesPlayed;
  final int bonusMinutes;
  final int bonusCheckpointSessions;

  Player({
    this.id,
    required this.name,
    this.totalSessions = 0,
    this.totalSpent = 0.0,
    this.totalMinutesPlayed = 0,
    this.bonusMinutes = 0,
    this.bonusCheckpointSessions = 0,
  });

  Player copyWith({
    int? id,
    String? name,
    int? totalSessions,
    double? totalSpent,
    int? totalMinutesPlayed,
    int? bonusMinutes,
    int? bonusCheckpointSessions,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      totalSessions: totalSessions ?? this.totalSessions,
      totalSpent: totalSpent ?? this.totalSpent,
      totalMinutesPlayed: totalMinutesPlayed ?? this.totalMinutesPlayed,
      bonusMinutes: bonusMinutes ?? this.bonusMinutes,
      bonusCheckpointSessions:
          bonusCheckpointSessions ?? this.bonusCheckpointSessions,
    );
  }

  factory Player.fromMap(Map<String, Object?> map) {
    return Player(
      id: map['id'] as int?,
      name: map['name'] as String,
      totalSessions: map['total_sessions'] as int,
      totalSpent: (map['total_spent'] as num).toDouble(),
      totalMinutesPlayed: map['total_minutes_played'] as int,
      bonusMinutes: map['bonus_minutes'] as int,
      bonusCheckpointSessions: map['bonus_checkpoint_sessions'] as int? ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'total_sessions': totalSessions,
      'total_spent': totalSpent,
      'total_minutes_played': totalMinutesPlayed,
      'bonus_minutes': bonusMinutes,
      'bonus_checkpoint_sessions': bonusCheckpointSessions,
    };
  }
}
