import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/waste_log.dart';

final wasteRepositoryProvider = Provider<WasteRepository>((ref) {
  return WasteRepository();
});

class WasteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<WasteLogEntry>> getWasteLogs() async {
    final db = await _dbHelper.database;
    final maps = await db.query('waste_log', orderBy: 'discarded_at DESC');
    return maps.map((e) => WasteLogEntry.fromMap(e)).toList();
  }

  Future<void> logDiscard(WasteLogEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert('waste_log', entry.toMap());
  }

  Future<void> deleteLog(int id) async {
    final db = await _dbHelper.database;
    await db.delete('waste_log', where: 'id = ?', whereArgs: [id]);
  }
}
