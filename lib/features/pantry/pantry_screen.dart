import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/filter_chip_bar.dart';
import '../../core/widgets/food_card.dart';
import '../../data/providers/food_provider.dart';

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortDialog() {
    final currentSort = ref.read(pantryFilterProvider).sortBy;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Sort items by',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildSortTile('Expiry date (Soonest first)', 'expiry_asc', currentSort),
                _buildSortTile('Expiry date (Latest first)', 'expiry_desc', currentSort),
                _buildSortTile('Name (A to Z)', 'name_asc', currentSort),
                _buildSortTile('Recently added', 'date_added', currentSort),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTile(String title, String value, String currentValue) {
    final isSelected = value == currentValue;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryDark)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        ref.read(pantryFilterProvider.notifier).state =
            ref.read(pantryFilterProvider).copyWith(sortBy: value);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = ref.watch(filteredFoodListProvider);
    final filterState = ref.watch(pantryFilterProvider);
    final foodAsync = ref.watch(foodListProvider);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Padding(
              padding: EdgeInsets.only(
                left: isTablet ? 32 : 20,
                right: isTablet ? 32 : 20,
                top: 20,
                bottom: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Pantry',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      foodAsync.when(
                        data: (items) => Text(
                          '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        loading: () => const Text('Loading items...'),
                        error: (_, __) => const Text('0 items'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _showSortDialog,
                        icon: const Icon(Icons.sort_rounded, color: AppColors.textPrimary),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F2ED),
                          shape: const CircleBorder(),
                        ),
                        tooltip: 'Sort items',
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () {
                          ref.read(pantryFilterProvider.notifier).state =
                              filterState.copyWith(isGridView: !filterState.isGridView);
                        },
                        icon: Icon(
                          filterState.isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                          color: AppColors.textPrimary,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F2ED),
                          shape: const CircleBorder(),
                        ),
                        tooltip: 'Toggle Grid/List',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 20,
                vertical: 10,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(pantryFilterProvider.notifier).state =
                      filterState.copyWith(searchQuery: val);
                },
                decoration: InputDecoration(
                  hintText: 'Search food...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(pantryFilterProvider.notifier).state =
                                filterState.copyWith(searchQuery: '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Location Filter Chips (All, Fridge, Freezer, Cupboard)
            FilterChipBar(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
              selectedId: filterState.locationFilter,
              onSelected: (loc) {
                ref.read(pantryFilterProvider.notifier).state =
                    filterState.copyWith(locationFilter: loc);
              },
              items: const [
                FilterChipItem(id: 'All', label: 'All'),
                FilterChipItem(id: 'Fridge', label: 'Fridge', icon: Icons.ac_unit_outlined),
                FilterChipItem(id: 'Freezer', label: 'Freezer', icon: Icons.kitchen_outlined),
                FilterChipItem(id: 'Cupboard', label: 'Cupboard', icon: Icons.inventory_2_outlined),
              ],
            ),
            const SizedBox(height: 8),

            // Secondary Status / Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
              child: Row(
                children: [
                  _buildSecondaryChip(
                    label: 'All Status',
                    isActive: filterState.statusFilter == 'all',
                    onTap: () {
                      ref.read(pantryFilterProvider.notifier).state =
                          filterState.copyWith(statusFilter: 'all');
                    },
                  ),
                  _buildSecondaryChip(
                    label: 'Expiring Soon',
                    isActive: filterState.statusFilter == 'soon',
                    onTap: () {
                      ref.read(pantryFilterProvider.notifier).state =
                          filterState.copyWith(statusFilter: 'soon');
                    },
                  ),
                  _buildSecondaryChip(
                    label: 'Expired',
                    isActive: filterState.statusFilter == 'expired',
                    onTap: () {
                      ref.read(pantryFilterProvider.notifier).state =
                          filterState.copyWith(statusFilter: 'expired');
                    },
                  ),
                  _buildSecondaryChip(
                    label: 'Low Stock',
                    isActive: filterState.statusFilter == 'low_stock',
                    onTap: () {
                      ref.read(pantryFilterProvider.notifier).state =
                          filterState.copyWith(statusFilter: 'low_stock');
                    },
                  ),
                  ...AppConstants.categories.map((c) => _buildSecondaryChip(
                        label: c.label,
                        isActive: filterState.categoryFilter == c.id,
                        onTap: () {
                          ref.read(pantryFilterProvider.notifier).state = filterState.copyWith(
                            categoryFilter: filterState.categoryFilter == c.id ? 'all' : c.id,
                          );
                        },
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Food List / Grid
            Expanded(
              child: foodAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryDark),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (allItems) {
                  if (filteredItems.isEmpty) {
                    if (allItems.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.inventory_2_outlined,
                        title: 'No items in pantry',
                        description: 'Add groceries to start tracking freshness and expiry.',
                        buttonText: 'Add Food',
                        onButtonPressed: () => context.push('/add-food'),
                      );
                    }
                    return const EmptyStateView(
                      icon: Icons.search_off_rounded,
                      title: 'No matching items',
                      description: 'Try adjusting your search query or filter chips.',
                    );
                  }

                  if (filterState.isGridView || isTablet) {
                    return GridView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 20,
                        vertical: 8,
                      ),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isTablet ? 2 : (width > 500 ? 2 : 1),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3.4,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return FoodCard(
                          item: item,
                          onTap: () => context.push('/food-details/${item.id}'),
                          showQuantityButtons: true,
                          onIncrement: () =>
                              ref.read(foodListProvider.notifier).adjustQuantity(item.id!, 1),
                          onDecrement: () =>
                              ref.read(foodListProvider.notifier).adjustQuantity(item.id!, -1),
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Dismissible(
                        key: Key('food_${item.id}'),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Row(
                            children: [
                              Icon(Icons.remove_circle_outline, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Use some (-1)',
                                  style: TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        secondaryBackground: Container(
                          decoration: BoxDecoration(
                            color: AppColors.statusExpired,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Delete',
                                  style: TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.bold)),
                              SizedBox(width: 8),
                              Icon(Icons.delete_outline, color: Colors.white),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Use some (-1)
                            await ref.read(foodListProvider.notifier).adjustQuantity(item.id!, -1);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Used 1 ${item.unit} of ${item.name}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                            return false;
                          } else {
                            // Delete with undo
                            return true;
                          }
                        },
                        onDismissed: (direction) async {
                          final deletedItem = item;
                          await ref.read(foodListProvider.notifier).deleteItem(item.id!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${deletedItem.name} removed from pantry'),
                                action: SnackBarAction(
                                  label: 'UNDO',
                                  textColor: AppColors.secondary,
                                  onPressed: () {
                                    ref.read(foodListProvider.notifier).addItem(deletedItem);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                        child: FoodCard(
                          item: item,
                          onTap: () => context.push('/food-details/${item.id}'),
                          showQuantityButtons: true,
                          onIncrement: () =>
                              ref.read(foodListProvider.notifier).adjustQuantity(item.id!, 1),
                          onDecrement: () =>
                              ref.read(foodListProvider.notifier).adjustQuantity(item.id!, -1),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE8F1EC) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppColors.primaryDark : const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primaryDark : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
