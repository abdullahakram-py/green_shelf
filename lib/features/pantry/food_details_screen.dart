import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/utils/expiry_calculator.dart';
import '../../core/widgets/quantity_stepper.dart';
import '../../data/models/food_item.dart';
import '../../data/providers/food_provider.dart';
import '../../data/providers/shopping_provider.dart';
import '../../data/providers/waste_provider.dart';

class FoodDetailsScreen extends ConsumerWidget {
  final int itemId;

  const FoodDetailsScreen({super.key, required this.itemId});

  void _showDiscardDialog(BuildContext context, WidgetRef ref, FoodItem item) {
    String selectedReason = AppConstants.discardReasons.first;
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Discard ${item.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record this in your food waste log to track patterns over time.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Reason for discard',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        items: AppConstants.discardReasons.map((r) {
                          return DropdownMenuItem(value: r, child: Text(r));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedReason = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Estimated Cost / Value (optional)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: costController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(hintText: 'e.g. 4.50'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final cost = double.tryParse(costController.text.trim());
                    await ref.read(wasteListProvider.notifier).logFoodItemDiscard(
                          item,
                          reason: selectedReason,
                          estimatedCost: cost,
                        );
                    await ref.read(foodListProvider.notifier).deleteItem(item.id!);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.name} logged as discarded.'),
                          backgroundColor: AppColors.statusExpired,
                        ),
                      );
                      context.pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.statusExpired,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Log Discard'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleUsedUp(BuildContext context, WidgetRef ref, FoodItem item) async {
    await ref.read(foodListProvider.notifier).deleteItem(item.id!);

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Item Used Up!'),
            content: Text('Would you like to add "${item.name}" to your shopping list?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                },
                child: const Text('No, thanks'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await ref.read(shoppingListProvider.notifier).addItem(
                        item.name,
                        quantity: item.quantity,
                        unit: item.unit,
                        category: item.category,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} added to Shopping List'),
                        backgroundColor: AppColors.primaryDark,
                      ),
                    );
                    context.pop();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
                child: const Text('Add to Shopping List'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodAsync = ref.watch(foodListProvider);

    return foodAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
      ),
      error: (err, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: Center(child: Text('Error: $err')),
      ),
      data: (items) {
        final itemMatches = items.where((i) => i.id == itemId);
        if (itemMatches.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(),
            body: const Center(child: Text('Item not found or has been removed.')),
          );
        }

        final item = itemMatches.first;
        final expiryInfo = ExpiryCalculator.getExpiryInfo(item.expiryDateTime);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text(
              item.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
                onPressed: () {
                  context.push('/edit-food', extra: item);
                },
                tooltip: 'Edit Food',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: expiryInfo.badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(200),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(expiryInfo.icon, size: 28, color: expiryInfo.textColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expiryInfo.label.toUpperCase(),
                                style: TextStyle(
                                  color: expiryInfo.textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Expiry: ${DateHelpers.formatReadable(item.expiryDateTime)}',
                                style: TextStyle(
                                  color: expiryInfo.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quantity Stepper Tile
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECECE6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Quantity',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantity == item.quantity.roundToDouble() ? item.quantity.toInt() : item.quantity} ${item.unit}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        QuantityStepper(
                          value: item.quantity,
                          unit: item.unit,
                          step: item.unit == 'kg' || item.unit == 'Litres' ? 0.5 : 1.0,
                          min: 0.0,
                          onChanged: (newQty) {
                            ref.read(foodListProvider.notifier).adjustQuantity(
                                  item.id!,
                                  newQty - item.quantity,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metadata Details Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFECECE6)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Category', item.category.toUpperCase(), Icons.category_outlined),
                        const Divider(height: 20),
                        _buildDetailRow('Storage Location', item.location, Icons.inventory_2_outlined),
                        const Divider(height: 20),
                        _buildDetailRow(
                          'Purchase Date',
                          item.purchaseDate != null
                              ? DateHelpers.formatReadable(item.purchaseDateTime!)
                              : 'Not recorded',
                          Icons.calendar_today_outlined,
                        ),
                        if (item.lowStockThreshold != null) ...[
                          const Divider(height: 20),
                          _buildDetailRow(
                            'Low Stock Threshold',
                            '≤ ${item.lowStockThreshold} ${item.unit}',
                            Icons.notifications_active_outlined,
                          ),
                        ],
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const Divider(height: 20),
                          _buildDetailRow('Notes', item.notes!, Icons.note_outlined),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions Section
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleUsedUp(context, ref, item),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('Used Up'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            side: const BorderSide(color: AppColors.primaryDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDiscardDialog(context, ref, item),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Discard'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.statusExpired,
                            side: const BorderSide(color: AppColors.statusExpired),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await ref.read(shoppingListProvider.notifier).addItem(
                              item.name,
                              quantity: item.quantity,
                              unit: item.unit,
                              category: item.category,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} added to Shopping List'),
                              backgroundColor: AppColors.primaryDark,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Add to Shopping List'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primaryDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F2ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textTertiary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dates shown are from the package. Check storage guidance and use your judgment.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textTertiary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
