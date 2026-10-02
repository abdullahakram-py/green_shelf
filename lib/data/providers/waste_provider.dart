import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../models/waste_log.dart';
import '../repositories/waste_repository.dart';

class WasteListNotifier extends StateNotifier<AsyncValue<List<WasteLogEntry>>> {
  final WasteRepository _repository;

  WasteListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLogs();
  }

  Future<void> loadLogs() async {
    try {
      state = const AsyncValue.loading();
      final logs = await _repository.getWasteLogs();
      state = AsyncValue.data(logs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logFoodItemDiscard(
    FoodItem item, {
    required String reason,
    double? estimatedCost,
  }) async {
    try {
      final entry = WasteLogEntry(
        itemName: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        reason: reason,
        estimatedCost: estimatedCost,
        discardedAt: DateTime.now().toIso8601String(),
      );
      await _repository.logDiscard(entry);
      await loadLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLog(int id) async {
    try {
      await _repository.deleteLog(id);
      await loadLogs();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final wasteListProvider =
    StateNotifierProvider<WasteListNotifier, AsyncValue<List<WasteLogEntry>>>((ref) {
  final repo = ref.watch(wasteRepositoryProvider);
  return WasteListNotifier(repo);
});
