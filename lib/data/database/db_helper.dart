import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/utils/date_helpers.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import '../models/shopping_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  static const String _dbName = 'green_shelf.db';
  static const int _dbVersion = 1;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Food Items Table
    await db.execute('''
      CREATE TABLE food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        low_stock_threshold REAL,
        purchase_date TEXT,
        expiry_date TEXT NOT NULL,
        location TEXT NOT NULL,
        notes TEXT,
        notification_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_food_expiry ON food_items(expiry_date)');
    await db.execute('CREATE INDEX idx_food_category ON food_items(category)');
    await db.execute('CREATE INDEX idx_food_location ON food_items(location)');

    // 2. Shopping List Table
    await db.execute('''
      CREATE TABLE shopping_list (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity REAL,
        unit TEXT,
        category TEXT,
        is_purchased INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 3. Recipes Table
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        prep_minutes INTEGER NOT NULL,
        difficulty TEXT,
        image_url TEXT,
        ingredients TEXT NOT NULL,
        ingredients_with_qty TEXT,
        instructions TEXT NOT NULL,
        tags TEXT
      )
    ''');

    // 4. Waste Log Table
    await db.execute('''
      CREATE TABLE waste_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        category TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT NOT NULL,
        reason TEXT NOT NULL,
        estimated_cost REAL,
        discarded_at TEXT NOT NULL
      )
    ''');

    // Seed initial recipes and demo pantry items
    await _seedInitialRecipes(db);
    await _seedDemoPantry(db);
  }

  Future<void> _seedInitialRecipes(Database db) async {
    try {
      final jsonString = await rootBundle.loadString('assets/recipes/recipes_seed.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final batch = db.batch();
      for (final item in jsonList) {
        final recipe = Recipe.fromMap(item as Map<String, dynamic>);
        batch.insert('recipes', recipe.toMap());
      }
      await batch.commit(noResult: true);
    } catch (e) {
      // Fallback in case asset loading fails during offline tests
      final batch = db.batch();
      const fallbackRecipe = Recipe(
        name: 'Spinach Omelette',
        category: 'Breakfast',
        prepMinutes: 10,
        difficulty: 'Easy',
        ingredients: ['spinach', 'egg', 'milk', 'cheese', 'butter'],
        instructions: [
          'Whisk eggs and milk with a pinch of salt.',
          'Sauté spinach in butter until wilted.',
          'Pour egg mixture over spinach, fold in cheese, and cook until golden.'
        ],
        tags: 'Quick, High Protein',
      );
      batch.insert('recipes', fallbackRecipe.toMap());
      await batch.commit(noResult: true);
    }
  }

  Future<void> _seedDemoPantry(Database db) async {
    final now = DateTime.now();
    final today = DateHelpers.stripTime(now);

    final demoItems = [
      FoodItem(
        name: 'Spinach',
        category: 'vegetable',
        quantity: 200,
        unit: 'g',
        lowStockThreshold: 100,
        purchaseDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 4))),
        expiryDate: DateHelpers.toIsoDate(today), // Expires today
        location: 'Fridge',
        notes: 'Fresh organic baby spinach',
        notificationId: 101,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
      FoodItem(
        name: 'Milk',
        category: 'dairy',
        quantity: 1,
        unit: 'Litres',
        lowStockThreshold: 0.5,
        purchaseDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 5))),
        expiryDate: DateHelpers.toIsoDate(today.add(const Duration(days: 1))), // Tomorrow
        location: 'Fridge',
        notes: 'Full cream milk',
        notificationId: 102,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
      FoodItem(
        name: 'Yogurt',
        category: 'dairy',
        quantity: 400,
        unit: 'g',
        lowStockThreshold: 150,
        purchaseDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 8))),
        expiryDate: DateHelpers.toIsoDate(today.add(const Duration(days: 2))), // 2 days
        location: 'Fridge',
        notes: 'Greek style yogurt',
        notificationId: 103,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
      FoodItem(
        name: 'Eggs',
        category: 'dairy',
        quantity: 6,
        unit: 'pcs',
        lowStockThreshold: 4,
        purchaseDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 2))),
        expiryDate: DateHelpers.toIsoDate(today.add(const Duration(days: 5))), // 5 days
        location: 'Fridge',
        notes: 'Farm fresh brown eggs',
        notificationId: 104,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
      FoodItem(
        name: 'Chicken Breast',
        category: 'meat',
        quantity: 500,
        unit: 'g',
        lowStockThreshold: 250,
        purchaseDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 7))),
        expiryDate: DateHelpers.toIsoDate(today.add(const Duration(days: 21))), // 3 weeks
        location: 'Freezer',
        notes: 'Skinless chicken fillets',
        notificationId: 105,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
      FoodItem(
        name: 'Basmati Rice',
        category: 'grains',
        quantity: 2,
        unit: 'kg',
        lowStockThreshold: 1,
        purchaseDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 30))),
        expiryDate: DateHelpers.toIsoDate(today.add(const Duration(days: 240))), // 8 months
        location: 'Cupboard',
        notes: 'Aromatic long grain',
        notificationId: 106,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
      FoodItem(
        name: 'Old Sliced Bread',
        category: 'grains',
        quantity: 1,
        unit: 'pack',
        lowStockThreshold: 1,
        purchaseDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 10))),
        expiryDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 2))), // Expired 2 days ago
        location: 'Cupboard',
        notes: 'White sandwich bread',
        notificationId: 107,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
      FoodItem(
        name: 'Tomatoes',
        category: 'vegetable',
        quantity: 4,
        unit: 'pcs',
        lowStockThreshold: 2,
        purchaseDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 3))),
        expiryDate: DateHelpers.toIsoDate(today.add(const Duration(days: 4))),
        location: 'Fridge',
        notes: 'Ripe salad tomatoes',
        notificationId: 108,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
      FoodItem(
        name: 'Butter',
        category: 'dairy',
        quantity: 250,
        unit: 'g',
        lowStockThreshold: 50,
        purchaseDate: DateHelpers.toIsoDate(today.subtract(const Duration(days: 14))),
        expiryDate: DateHelpers.toIsoDate(today.add(const Duration(days: 45))),
        location: 'Fridge',
        notes: 'Unsalted butter',
        notificationId: 109,
        createdAt: now.toIso8601String(),
        updatedAt: now.toIso8601String(),
      ),
    ];

    final batch = db.batch();
    for (final item in demoItems) {
      batch.insert('food_items', item.toMap());
    }

    // Demo shopping items
    final demoShop = [
      const ShoppingItem(name: 'Cheddar Cheese', quantity: 200, unit: 'g', category: 'dairy', createdAt: '2026-10-01'),
      const ShoppingItem(name: 'Olive Oil', quantity: 1, unit: 'Litres', category: 'packaged', createdAt: '2026-10-01'),
      const ShoppingItem(name: 'Apples', quantity: 6, unit: 'pcs', category: 'fruit', isPurchased: true, createdAt: '2026-10-01'),
    ];
    for (final item in demoShop) {
      batch.insert('shopping_list', item.toMap());
    }

    await batch.commit(noResult: true);
  }

  /// Reset database and reseed sample data
  Future<void> resetToSampleData() async {
    final db = await database;
    await db.delete('food_items');
    await db.delete('shopping_list');
    await db.delete('recipes');
    await db.delete('waste_log');
    await _seedInitialRecipes(db);
    await _seedDemoPantry(db);
  }
}
