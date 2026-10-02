import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/expiry_calculator.dart';
import '../models/food_item.dart';
import '../repositories/food_repository.dart';

class PantryFilterState {
  final String searchQuery;
  final String locationFilter; // 'All', 'Fridge', 'Freezer', 'Cupboard'
  final String categoryFilter; // 'all' or category id
  final String statusFilter; // 'all', 'expired', 'soon', 'fresh', 'low_stock'
  final String sortBy; // 'expiry_asc', 'expiry_desc', 'name_asc', 'date_added'
  final bool isGridView;

  const PantryFilterState({
    this.searchQuery = '',
    this.locationFilter = 'All',
    this.categoryFilter = 'all',
    this.statusFilter = 'all',
    this.sortBy = 'expiry_asc',
    this.isGridView = false,
  });

  PantryFilterState copyWith({
    String? searchQuery,
    String? locationFilter,
    String? categoryFilter,
    String? statusFilter,
    String? sortBy,
    bool? isGridView,
  }) {
    return PantryFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      locationFilter: locationFilter ?? this.locationFilter,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      sortBy: sortBy ?? this.sortBy,
      isGridView: isGridView ?? this.isGridView,
    );
  }
}

class FoodListNotifier extends StateNotifier<AsyncValue<List<FoodItem>>> {
  final FoodRepository _repository;

  FoodListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadFoodItems();
  }

  Future<void> loadFoodItems() async {
    try {
      state = const AsyncValue.loading();
      final items = await _repository.getAllFoodItems();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<FoodItem?> addItem(FoodItem item) async {
    try {
      final saved = await _repository.insertFoodItem(item);
      await loadFoodItems();
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<void> updateItem(FoodItem item) async {
    try {
      await _repository.updateItem(item);
      await loadFoodItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _repository.deleteFoodItem(id);
      await loadFoodItems();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> adjustQuantity(int id, double delta) async {
    final currentList = state.value;
    if (currentList == null) return;
    final item = currentList.firstWhere((i) => i.id == id);
    final newQty = (item.quantity + delta).clamp(0.0, 99999.0);
    await _repository.updateQuantity(id, newQty);
    await loadFoodItems();
  }
}

final foodListProvider =
    StateNotifierProvider<FoodListNotifier, AsyncValue<List<FoodItem>>>((ref) {
  final repo = ref.watch(foodRepositoryProvider);
  return FoodListNotifier(repo);
});

final pantryFilterProvider =
    StateProvider<PantryFilterState>((ref) => const PantryFilterState());

final filteredFoodListProvider = Provider<List<FoodItem>>((ref) {
  final foodAsync = ref.watch(foodListProvider);
  final filter = ref.watch(pantryFilterProvider);

  return foodAsync.when(
    data: (items) {
      var list = List<FoodItem>.from(items);

      // 1. Search Query
      if (filter.searchQuery.trim().isNotEmpty) {
        final query = filter.searchQuery.trim().toLowerCase();
        list = list.where((i) => i.name.toLowerCase().contains(query)).toList();
      }

      // 2. Location Filter
      if (filter.locationFilter != 'All') {
        list = list
            .where((i) => i.location.toLowerCase() == filter.locationFilter.toLowerCase())
            .toList();
      }

      // 3. Category Filter
      if (filter.categoryFilter != 'all') {
        list = list
            .where((i) => i.category.toLowerCase() == filter.categoryFilter.toLowerCase())
            .toList();
      }

      // 4. Status Filter
      if (filter.statusFilter != 'all') {
        final now = DateTime.now();
        if (filter.statusFilter == 'expired') {
          list = list.where((i) => i.isExpired(now: now)).toList();
        } else if (filter.statusFilter == 'soon') {
          list = list.where((i) => i.isExpiringSoon(now: now)).toList();
        } else if (filter.statusFilter == 'fresh') {
          list = list.where((i) =>
              ExpiryCalculator.statusFor(i.expiryDateTime, now, 3) == ExpiryStatus.fresh).toList();
        } else if (filter.statusFilter == 'low_stock') {
          list = list.where((i) => i.isLowStock).toList();
        }
      }

      // 5. Sorting
      list.sort((a, b) {
        if (filter.sortBy == 'expiry_asc') {
          return a.expiryDate.compareTo(b.expiryDate);
        } else if (filter.sortBy == 'expiry_desc') {
          return b.expiryDate.compareTo(a.expiryDate);
        } else if (filter.sortBy == 'name_asc') {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        } else if (filter.sortBy == 'date_added') {
          return b.createdAt.compareTo(a.createdAt);
        }
        return 0;
      });

      return list;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

class DashboardStats {
  final int totalItems;
  final int expiringSoonCount;
  final int expiredCount;
  final int lowStockCount;

  const DashboardStats({
    required this.totalItems,
    required this.expiringSoonCount,
    required this.expiredCount,
    required this.lowStockCount,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final foodAsync = ref.watch(foodListProvider);
  return foodAsync.when(
    data: (items) {
      final now = DateTime.now();
      int expiringSoon = 0;
      int expired = 0;
      int lowStock = 0;

      for (final item in items) {
        final status = ExpiryCalculator.statusFor(item.expiryDateTime, now, 3);
        if (status == ExpiryStatus.expired) {
          expired++;
        } else if (status == ExpiryStatus.soon || status == ExpiryStatus.today) {
          expiringSoon++;
        }
        if (item.isLowStock) {
          lowStock++;
        }
      }

      return DashboardStats(
        totalItems: items.length,
        expiringSoonCount: expiringSoon,
        expiredCount: expired,
        lowStockCount: lowStock,
      );
    },
    loading: () => const DashboardStats(
      totalItems: 0,
      expiringSoonCount: 0,
      expiredCount: 0,
      lowStockCount: 0,
    ),
    error: (_, __) => const DashboardStats(
      totalItems: 0,
      expiringSoonCount: 0,
      expiredCount: 0,
      lowStockCount: 0,
    ),
  );
});

final useTheseFirstItemsProvider = Provider<List<FoodItem>>((ref) {
  final foodAsync = ref.watch(foodListProvider);
  return foodAsync.when(
    data: (items) {
      final activeItems = items.where((i) => !i.isExpired()).toList();
      activeItems.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
      return activeItems.take(5).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final pastItemNamesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(foodRepositoryProvider);
  return await repo.getDistinctPastItemNames();
});
