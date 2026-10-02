import '../../core/utils/date_helpers.dart';
import '../../core/utils/expiry_calculator.dart';

class FoodItem {
  final int? id;
  final String name;
  final String category;
  final double quantity;
  final String unit;
  final double? lowStockThreshold;
  final String? purchaseDate; // ISO-8601 string (yyyy-MM-dd)
  final String expiryDate; // ISO-8601 string (yyyy-MM-dd)
  final String location; // 'Fridge', 'Freezer', 'Cupboard'
  final String? notes;
  final int? notificationId;
  final String createdAt;
  final String updatedAt;

  const FoodItem({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    this.lowStockThreshold,
    this.purchaseDate,
    required this.expiryDate,
    required this.location,
    this.notes,
    this.notificationId,
    required this.createdAt,
    required this.updatedAt,
  });

  DateTime get expiryDateTime => DateHelpers.parseIsoDate(expiryDate);
  DateTime? get purchaseDateTime =>
      purchaseDate != null ? DateHelpers.parseIsoDate(purchaseDate!) : null;

  bool get isLowStock =>
      lowStockThreshold != null && lowStockThreshold! > 0 && quantity <= lowStockThreshold!;

  bool isExpired({DateTime? now}) =>
      ExpiryCalculator.statusFor(expiryDateTime, now ?? DateTime.now(), 3) == ExpiryStatus.expired;

  bool isExpiringSoon({DateTime? now, int soonDays = 3}) {
    final status = ExpiryCalculator.statusFor(expiryDateTime, now ?? DateTime.now(), soonDays);
    return status == ExpiryStatus.soon || status == ExpiryStatus.today;
  }

  FoodItem copyWith({
    int? id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    double? lowStockThreshold,
    String? purchaseDate,
    String? expiryDate,
    String? location,
    String? notes,
    int? notificationId,
    String? createdAt,
    String? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category.toLowerCase(),
      'quantity': quantity,
      'unit': unit,
      'low_stock_threshold': lowStockThreshold,
      'purchase_date': purchaseDate,
      'expiry_date': expiryDate,
      'location': location,
      'notes': notes,
      'notification_id': notificationId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      lowStockThreshold: map['low_stock_threshold'] != null
          ? (map['low_stock_threshold'] as num).toDouble()
          : null,
      purchaseDate: map['purchase_date'] as String?,
      expiryDate: map['expiry_date'] as String,
      location: map['location'] as String,
      notes: map['notes'] as String?,
      notificationId: map['notification_id'] as int?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }
}
