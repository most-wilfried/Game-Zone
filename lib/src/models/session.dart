class Session {
  final int? id;
  final int stationId;
  final String stationName;
  final String playerName;
  final double amountPaid;
  final int totalMinutes;
  final int minutesUsed;
  final int minutesRemaining;
  final String status;
  final String startedAt;
  final String? pausedAt;
  final String? expiresAt;
  final String? completedAt;
  final String? startedByName;
  final String? startedByRole;
  final String? completedByName;
  final String? completedByRole;

  Session({
    this.id,
    required this.stationId,
    required this.stationName,
    required this.playerName,
    required this.amountPaid,
    required this.totalMinutes,
    required this.minutesUsed,
    required this.minutesRemaining,
    this.status = 'active',
    required this.startedAt,
    this.pausedAt,
    this.expiresAt,
    this.completedAt,
    this.startedByName,
    this.startedByRole,
    this.completedByName,
    this.completedByRole,
  });

  Session copyWith({
    int? id,
    int? stationId,
    String? stationName,
    String? playerName,
    double? amountPaid,
    int? totalMinutes,
    int? minutesUsed,
    int? minutesRemaining,
    String? status,
    String? startedAt,
    String? pausedAt,
    String? expiresAt,
    String? completedAt,
    String? startedByName,
    String? startedByRole,
    String? completedByName,
    String? completedByRole,
  }) {
    return Session(
      id: id ?? this.id,
      stationId: stationId ?? this.stationId,
      stationName: stationName ?? this.stationName,
      playerName: playerName ?? this.playerName,
      amountPaid: amountPaid ?? this.amountPaid,
      totalMinutes: totalMinutes ?? this.totalMinutes,
      minutesUsed: minutesUsed ?? this.minutesUsed,
      minutesRemaining: minutesRemaining ?? this.minutesRemaining,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      startedByName: startedByName ?? this.startedByName,
      startedByRole: startedByRole ?? this.startedByRole,
      completedByName: completedByName ?? this.completedByName,
      completedByRole: completedByRole ?? this.completedByRole,
    );
  }

  factory Session.fromMap(Map<String, Object?> map) {
    return Session(
      id: map['id'] as int?,
      stationId: map['station_id'] as int,
      stationName: map['station_name'] as String,
      playerName: map['player_name'] as String,
      amountPaid: (map['amount_paid'] as num).toDouble(),
      totalMinutes: map['total_minutes'] as int,
      minutesUsed: map['minutes_used'] as int,
      minutesRemaining: map['minutes_remaining'] as int,
      status: map['status'] as String,
      startedAt: map['started_at'] as String,
      pausedAt: map['paused_at'] as String?,
      expiresAt: map['expires_at'] as String?,
      completedAt: map['completed_at'] as String?,
      startedByName: map['started_by_name'] as String?,
      startedByRole: map['started_by_role'] as String?,
      completedByName: map['completed_by_name'] as String?,
      completedByRole: map['completed_by_role'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'station_id': stationId,
      'station_name': stationName,
      'player_name': playerName,
      'amount_paid': amountPaid,
      'total_minutes': totalMinutes,
      'minutes_used': minutesUsed,
      'minutes_remaining': minutesRemaining,
      'status': status,
      'started_at': startedAt,
      'paused_at': pausedAt,
      'expires_at': expiresAt,
      'completed_at': completedAt,
      'started_by_name': startedByName,
      'started_by_role': startedByRole,
      'completed_by_name': completedByName,
      'completed_by_role': completedByRole,
    };
  }
}
