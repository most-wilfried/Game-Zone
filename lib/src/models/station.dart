class Station {
  final int? id;
  final String name;
  final String reference;
  final String consoleType;
  final String status;
  final double totalHoursUsed;
  final String? notes;

  Station({
    this.id,
    required this.name,
    this.reference = '',
    required this.consoleType,
    this.status = 'libre',
    this.totalHoursUsed = 0.0,
    this.notes,
  });

  Station copyWith({
    int? id,
    String? name,
    String? reference,
    String? consoleType,
    String? status,
    double? totalHoursUsed,
    String? notes,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      consoleType: consoleType ?? this.consoleType,
      status: status ?? this.status,
      totalHoursUsed: totalHoursUsed ?? this.totalHoursUsed,
      notes: notes ?? this.notes,
    );
  }

  factory Station.fromMap(Map<String, Object?> map) {
    return Station(
      id: map['id'] as int?,
      name: map['name'] as String,
      reference: map['reference'] as String? ?? '',
      consoleType: map['console_type'] as String,
      status: map['status'] as String,
      totalHoursUsed: (map['total_hours_used'] as num).toDouble(),
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'reference': reference,
      'console_type': consoleType,
      'status': status,
      'total_hours_used': totalHoursUsed,
      'notes': notes,
    };
  }
}
