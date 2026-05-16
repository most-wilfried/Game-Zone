class InventoryItem {
  final int? id;
  final String name;
  final String type;
  final String status;
  final String reference;
  final int assignedStationId;
  final String? assignedStationName;
  final double purchasePrice;
  final double salePrice;
  final double hoursUsed;
  final double maxHoursBeforeWear;
  final String wearLevel;
  final String? serialNumber;
  final String? notes;

  InventoryItem({
    this.id,
    required this.name,
    required this.type,
    this.status = 'en_stock',
    this.reference = '',
    this.assignedStationId = 0,
    this.assignedStationName,
    this.purchasePrice = 0.0,
    this.salePrice = 0.0,
    this.hoursUsed = 0.0,
    this.maxHoursBeforeWear = 400.0,
    this.wearLevel = 'bon',
    this.serialNumber,
    this.notes,
  });

  InventoryItem copyWith({
    int? id,
    String? name,
    String? type,
    String? status,
    String? reference,
    int? assignedStationId,
    String? assignedStationName,
    double? purchasePrice,
    double? salePrice,
    double? hoursUsed,
    double? maxHoursBeforeWear,
    String? wearLevel,
    String? serialNumber,
    String? notes,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      reference: reference ?? this.reference,
      assignedStationId: assignedStationId ?? this.assignedStationId,
      assignedStationName: assignedStationName ?? this.assignedStationName,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      salePrice: salePrice ?? this.salePrice,
      hoursUsed: hoursUsed ?? this.hoursUsed,
      maxHoursBeforeWear: maxHoursBeforeWear ?? this.maxHoursBeforeWear,
      wearLevel: wearLevel ?? this.wearLevel,
      serialNumber: serialNumber ?? this.serialNumber,
      notes: notes ?? this.notes,
    );
  }

  factory InventoryItem.fromMap(Map<String, Object?> map) {
    return InventoryItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
      reference: map['reference'] as String? ?? map['serial_number'] as String? ?? '',
      assignedStationId: map['assigned_station_id'] as int,
      assignedStationName: map['assigned_station_name'] as String?,
      purchasePrice: (map['purchase_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num).toDouble(),
      hoursUsed: (map['hours_used'] as num).toDouble(),
      maxHoursBeforeWear: (map['max_hours_before_wear'] as num).toDouble(),
      wearLevel: map['wear_level'] as String,
      serialNumber: map['serial_number'] as String?,
      notes: map['notes'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'reference': reference,
      'assigned_station_id': assignedStationId,
      'assigned_station_name': assignedStationName,
      'purchase_price': purchasePrice,
      'sale_price': salePrice,
      'hours_used': hoursUsed,
      'max_hours_before_wear': maxHoursBeforeWear,
      'wear_level': wearLevel,
      'serial_number': serialNumber,
      'notes': notes,
    };
  }
}
