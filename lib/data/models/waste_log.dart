class WasteLogEntry {
  final int? id;
  final String itemName;
  final String category;
  final double quantity;
  final String unit;
  final String reason;
  final double? estimatedCost;
  final String discardedAt;

  const WasteLogEntry({
    this.id,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.reason,
    this.estimatedCost,
    required this.discardedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'item_name': itemName,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'reason': reason,
      'estimated_cost': estimatedCost,
      'discarded_at': discardedAt,
    };
  }

  factory WasteLogEntry.fromMap(Map<String, dynamic> map) {
    return WasteLogEntry(
      id: map['id'] as int?,
      itemName: map['item_name'] as String,
      category: map['category'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      reason: map['reason'] as String,
      estimatedCost: map['estimated_cost'] != null
          ? (map['estimated_cost'] as num).toDouble()
          : null,
      discardedAt: map['discarded_at'] as String,
    );
  }
}
