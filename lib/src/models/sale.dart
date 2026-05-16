class Sale {
  final int? id;
  final String type;
  final String description;
  final double amount;
  final int sessionId;
  final int inventoryItemId;
  final String? clientName;
  final String createdAt;

  Sale({
    this.id,
    required this.type,
    required this.description,
    required this.amount,
    this.sessionId = 0,
    this.inventoryItemId = 0,
    this.clientName,
    required this.createdAt,
  });

  factory Sale.fromMap(Map<String, Object?> map) {
    return Sale(
      id: map['id'] as int?,
      type: map['type'] as String,
      description: map['description'] as String,
      amount: (map['amount'] as num).toDouble(),
      sessionId: map['session_id'] as int,
      inventoryItemId: map['inventory_item_id'] as int,
      clientName: map['client_name'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
      'session_id': sessionId,
      'inventory_item_id': inventoryItemId,
      'client_name': clientName,
      'created_at': createdAt,
    };
  }
}
