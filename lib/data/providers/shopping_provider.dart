import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_item.dart';
import '../models/shopping_item.dart';
import '../repositories/shopping_repository.dart';
import 'food_provider.dart';

class ShoppingListNotifier extends StateNotifier<AsyncValue<List<ShoppingItem>>> {
  final ShoppingRepository _repository;

  ShoppingListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repository.getShoppingItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addItem(String name, {double? quantity, String? unit, String? category}) async {
    try {
      final item = ShoppingItem(
        name: name.trim(),
        quantity: quantity,
        unit: unit,
        category: category,
        createdAt: DateTime.now().toIso8601String(),
      );
      await _repository.insertItem(item);
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addMultipleItems(List<String> names) async {
    try {
      for (final name in names) {
        if (name.trim().isNotEmpty) {
          final item = ShoppingItem(
            name: name.trim(),
            createdAt: DateTime.now().toIso8601String(),
          );
          await _repository.insertItem(item);
        }
      }
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> toggleItemPurchased(int id, bool isPurchased) async {
    try {
      await _repository.togglePurchased(id, isPurchased);
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _repository.deleteItem(id);
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clearPurchased() async {
    try {
      await _repository.clearCompleted();
      await loadItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, AsyncValue<List<ShoppingItem>>>((ref) {
  final repo = ref.watch(shoppingRepositoryProvider);
  return ShoppingListNotifier(repo);
});

/// Suggestions for shopping list based on low-stock pantry items
final pantryRestockSuggestionsProvider = Provider<List<FoodItem>>((ref) {
  final foodAsync = ref.watch(foodListProvider);
  final shoppingAsync = ref.watch(shoppingListProvider);

  return foodAsync.when(
    data: (pantryItems) {
      final shoppingNames = shoppingAsync.asData?.value.map((s) => s.name.toLowerCase()).toSet() ?? {};
      return pantryItems.where((pantryItem) {
        final isLow = pantryItem.isLowStock || pantryItem.quantity <= 0;
        final alreadyInShop = shoppingNames.contains(pantryItem.name.toLowerCase());
        return isLow && !alreadyInShop;
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
