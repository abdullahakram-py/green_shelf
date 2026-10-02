import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/shopping_item.dart';

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository();
});

class ShoppingRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<ShoppingItem>> getShoppingItems() async {
    final db = await _dbHelper.database;
    final maps = await db.query('shopping_list', orderBy: 'is_purchased ASC, id DESC');
    return maps.map((e) => ShoppingItem.fromMap(e)).toList();
  }

  Future<ShoppingItem> insertItem(ShoppingItem item) async {
    final db = await _dbHelper.database;
    final id = await db.insert('shopping_list', item.toMap());
    return item.copyWith(id: id);
  }

  Future<void> updateItem(ShoppingItem item) async {
    final db = await _dbHelper.database;
    await db.update(
      'shopping_list',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> togglePurchased(int id, bool isPurchased) async {
    final db = await _dbHelper.database;
    await db.update(
      'shopping_list',
      {'is_purchased': isPurchased ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteItem(int id) async {
    final db = await _dbHelper.database;
    await db.delete('shopping_list', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCompleted() async {
    final db = await _dbHelper.database;
    await db.delete('shopping_list', where: 'is_purchased = ?', whereArgs: [1]);
  }
}
