import 'package:flutter/material.dart';

class FoodCategory {
  final String id;
  final String label;
  final IconData icon;

  const FoodCategory({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class AppConstants {
  AppConstants._();

  static const String appName = 'Green Shelf';
  static const String appTagline = 'Smart Food Expiry & Pantry Manager';

  // Categories
  static const List<FoodCategory> categories = [
    FoodCategory(id: 'dairy', label: 'Dairy', icon: Icons.water_drop_outlined),
    FoodCategory(id: 'fruit', label: 'Fruit', icon: Icons.apple_outlined),
    FoodCategory(id: 'vegetable', label: 'Veg', icon: Icons.eco_outlined),
    FoodCategory(id: 'meat', label: 'Meat', icon: Icons.set_meal_outlined),
    FoodCategory(id: 'grains', label: 'Grains', icon: Icons.grain_outlined),
    FoodCategory(id: 'beverage', label: 'Beverage', icon: Icons.local_drink_outlined),
    FoodCategory(id: 'packaged', label: 'Packaged', icon: Icons.inventory_2_outlined),
    FoodCategory(id: 'other', label: 'Other', icon: Icons.category_outlined),
  ];

  // Storage Locations
  static const List<String> storageLocations = ['Fridge', 'Freezer', 'Cupboard'];

  // Measurement Units
  static const List<String> units = ['pcs', 'kg', 'g', 'Litres', 'ml', 'pack', 'cans'];

  // Default reminder options (in days before expiry)
  static const List<int> reminderLeadDayOptions = [1, 2, 3, 7];

  // Common quick expiry presets (days)
  static const List<int> quickExpiryPresets = [3, 7, 30];

  // Discard reasons
  static const List<String> discardReasons = ['Expired', 'Spoiled', 'Unused / Leftover', 'Other'];
}
