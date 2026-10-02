class ShoppingItem {
  final int? id;
  final String name;
  final double? quantity;
  final String? unit;
  final String? category;
  final bool isPurchased;
  final String createdAt;

  const ShoppingItem({
    this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.category,
    this.isPurchased = false,
    required this.createdAt,
  });

  ShoppingItem copyWith({
    int? id,
    String? name,
    double? quantity,
    String? unit,
    String? category,
    bool? isPurchased,
    String? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'is_purchased': isPurchased ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      quantity: map['quantity'] != null ? (map['quantity'] as num).toDouble() : null,
      unit: map['unit'] as String?,
      category: map['category'] as String?,
      isPurchased: (map['is_purchased'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as String,
    );
  }
}
