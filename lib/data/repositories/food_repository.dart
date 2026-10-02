import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/food_item.dart';
import '../services/notification_service.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository();
});

class FoodRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<FoodItem>> getAllFoodItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query('food_items', orderBy: 'expiry_date ASC');
    return maps.map((e) => FoodItem.fromMap(e)).toList();
  }

  Future<FoodItem?> getFoodItemById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('food_items', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return FoodItem.fromMap(maps.first);
  }

  Future<FoodItem> insertFoodItem(FoodItem item) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final itemToInsert = item.copyWith(createdAt: now, updatedAt: now);

    final id = await db.insert('food_items', itemToInsert.toMap());
    final savedItem = itemToInsert.copyWith(id: id);

    // Schedule notification
    await NotificationService.instance.scheduleExpiryNotification(savedItem);

    return savedItem;
  }

  Future<void> updateItem(FoodItem item) => updateFoodItem(item);

  Future<void> updateFoodItem(FoodItem item) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final itemToUpdate = item.copyWith(updatedAt: now);

    await db.update(
      'food_items',
      itemToUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    // Cancel old and reschedule
    if (item.id != null) {
      await NotificationService.instance.scheduleExpiryNotification(itemToUpdate);
    }
  }

  Future<void> deleteFoodItem(int id) async {
    final db = await _dbHelper.database;
    await db.delete('food_items', where: 'id = ?', whereArgs: [id]);
    final notificationId = NotificationService.instance.generateNotificationId(id);
    await NotificationService.instance.cancelNotification(notificationId);
  }

  Future<void> updateQuantity(int id, double newQuantity) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'food_items',
      {'quantity': newQuantity, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> getDistinctPastItemNames() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT DISTINCT name FROM food_items ORDER BY name ASC');
    return result.map((e) => e['name'] as String).toList();
  }
}
