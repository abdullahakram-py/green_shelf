import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/food_item.dart';
import '../../data/models/shopping_item.dart';
import '../../data/providers/shopping_provider.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key});

  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final TextEditingController _quickAddController = TextEditingController();
  bool _isBoughtExpanded = true;

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  void _onQuickAdd() {
    final text = _quickAddController.text.trim();
    if (text.isNotEmpty) {
      ref.read(shoppingListProvider.notifier).addItem(text);
      _quickAddController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppingAsync = ref.watch(shoppingListProvider);
    final restockSuggestions = ref.watch(pantryRestockSuggestionsProvider);
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shopping List',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Plan groceries and restock pantry effortlessly',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    onSelected: (val) {
                      if (val == 'clear_completed') {
                        ref.read(shoppingListProvider.notifier).clearPurchased();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cleared bought items')),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'clear_completed',
                        child: Row(
                          children: [
                            Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.statusExpired),
                            SizedBox(width: 8),
                            Text('Clear bought items'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Add Input Field
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 20,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quickAddController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _onQuickAdd(),
                      decoration: const InputDecoration(
                        hintText: 'Add grocery item to buy...',
                        prefixIcon: Icon(Icons.add_shopping_cart_rounded, color: AppColors.textTertiary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _onQuickAdd,
                    icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),

            // Low Stock Restock Suggestions Banner
            if (restockSuggestions.isNotEmpty) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 20,
                  vertical: 4,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notifications_active_outlined, size: 16, color: Color(0xFFB45309)),
                          SizedBox(width: 6),
                          Text(
                            'Low Stock Suggestions',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: restockSuggestions.map((food) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text('+ ${food.name}'),
                                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Color(0xFFFDE68A)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                onPressed: () {
                                  ref.read(shoppingListProvider.notifier).addItem(
                                        food.name,
                                        quantity: food.quantity,
                                        unit: food.unit,
                                        category: food.category,
                                      );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),

            // Shopping Items List
            Expanded(
              child: shoppingAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryDark),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyStateView(
                      icon: Icons.shopping_basket_outlined,
                      title: 'Shopping list is empty',
                      description: 'Type items above or add missing ingredients from recipes.',
                    );
                  }

                  final pendingItems = items.where((i) => !i.isPurchased).toList();
                  final boughtItems = items.where((i) => i.isPurchased).toList();

                  return ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 20,
                      vertical: 8,
                    ),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Pending Items Section
                      if (pendingItems.isNotEmpty) ...[
                        const Text(
                          'To Buy',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...pendingItems.map((item) => _buildShoppingItemTile(context, item)),
                        const SizedBox(height: 16),
                      ],

                      // Bought Items Section
                      if (boughtItems.isNotEmpty) ...[
                        InkWell(
                          onTap: () => setState(() => _isBoughtExpanded = !_isBoughtExpanded),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  _isBoughtExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_right_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Bought (${boughtItems.length})',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isBoughtExpanded) ...[
                          const SizedBox(height: 8),
                          ...boughtItems.map((item) => _buildShoppingItemTile(context, item)),
                        ],
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShoppingItemTile(BuildContext context, ShoppingItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFECECE6)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        leading: Checkbox(
          value: item.isPurchased,
          activeColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          onChanged: (val) {
            ref.read(shoppingListProvider.notifier).toggleItemPurchased(item.id!, val ?? false);
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: item.isPurchased ? TextDecoration.lineThrough : null,
            color: item.isPurchased ? AppColors.textTertiary : AppColors.textPrimary,
          ),
        ),
        subtitle: item.quantity != null
            ? Text(
                '${item.quantity == item.quantity?.roundToDouble() ? item.quantity?.toInt() : item.quantity} ${item.unit ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.isPurchased)
              IconButton(
                icon: const Icon(Icons.add_to_photos_rounded, color: AppColors.primaryDark, size: 20),
                tooltip: 'Move to pantry',
                onPressed: () {
                  // Navigate to Add Food form prefilled
                  context.push(
                    '/add-food',
                    extra: FoodItem(
                      name: item.name,
                      category: item.category ?? 'packaged',
                      quantity: item.quantity ?? 1,
                      unit: item.unit ?? 'pcs',
                      expiryDate: DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10),
                      location: 'Fridge',
                      createdAt: DateTime.now().toIso8601String(),
                      updatedAt: DateTime.now().toIso8601String(),
                    ),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textTertiary),
              onPressed: () {
                ref.read(shoppingListProvider.notifier).deleteItem(item.id!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
