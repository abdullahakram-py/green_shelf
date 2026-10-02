import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helpers.dart';
import '../../data/database/db_helper.dart';
import '../../data/models/waste_log.dart';
import '../../data/providers/food_provider.dart';
import '../../data/providers/recipes_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../../data/providers/shopping_provider.dart';
import '../../data/providers/waste_provider.dart';
import '../../data/services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showTimePicker(BuildContext context, WidgetRef ref, int currentHour, int currentMinute) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: currentMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      await ref.read(settingsProvider.notifier).updateReminderTime(picked.hour, picked.minute);
    }
  }

  void _showWasteHistoryDialog(BuildContext context, List<WasteLogEntry> logs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Food Waste History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (logs.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          'No discarded items recorded yet. Great job!',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              log.itemName,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'Reason: ${log.reason} · ${DateHelpers.formatShort(DateTime.parse(log.discardedAt))}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: Text(
                              '${log.quantity == log.quantity.roundToDouble() ? log.quantity.toInt() : log.quantity} ${log.unit}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.statusExpired,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final wasteAsync = ref.watch(wasteListProvider);
    final wasteLogs = wasteAsync.asData?.value ?? [];

    final timeString = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: settings.reminderHour, minute: settings.reminderMinute),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Notifications Section
            _buildSectionTitle('Reminders & Notifications'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECECE6)),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Default Reminder Lead Time',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text('${settings.reminderLeadDays} days before expiry',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: settings.reminderLeadDays,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('1 day')),
                          DropdownMenuItem(value: 2, child: Text('2 days')),
                          DropdownMenuItem(value: 3, child: Text('3 days')),
                          DropdownMenuItem(value: 7, child: Text('7 days')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(settingsProvider.notifier).updateLeadDays(val);
                          }
                        },
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Daily Reminder Time',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text(timeString,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    trailing: TextButton(
                      onPressed: () => _showTimePicker(
                        context,
                        ref,
                        settings.reminderHour,
                        settings.reminderMinute,
                      ),
                      child: const Text('Change', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Notification Permission',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: const Text('Tap to ensure notification permissions are granted',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    trailing: ElevatedButton(
                      onPressed: () async {
                        final granted = await NotificationService.instance.requestPermissions();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(granted
                                  ? 'Notifications enabled successfully'
                                  : 'Notification permission requested'),
                              backgroundColor: AppColors.primaryDark,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        foregroundColor: AppColors.primaryDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Check'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Expiry Threshold
            _buildSectionTitle('Pantry & Shelf Life Thresholds'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECECE6)),
              ),
              child: ListTile(
                title: const Text('Expiring Soon Threshold',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: Text('Items expiring within ${settings.expiringSoonThreshold} days are marked as "Soon"',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: settings.expiringSoonThreshold,
                    items: const [
                      DropdownMenuItem(value: 2, child: Text('2 days')),
                      DropdownMenuItem(value: 3, child: Text('3 days')),
                      DropdownMenuItem(value: 5, child: Text('5 days')),
                      DropdownMenuItem(value: 7, child: Text('7 days')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).updateExpiringSoonThreshold(val);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Waste Analytics Summary
            _buildSectionTitle('Food Waste Tracker'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECECE6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recorded Waste',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${wasteLogs.length} items discarded',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton(
                        onPressed: () => _showWasteHistoryDialog(context, wasteLogs),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryDark),
                          foregroundColor: AppColors.primaryDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View Log'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data & System Actions
            _buildSectionTitle('Data & Demo Reset'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECECE6)),
              ),
              child: ListTile(
                leading: const Icon(Icons.refresh_rounded, color: AppColors.primaryDark),
                title: const Text('Reset Sample Pantry Data',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('Restores full demo inventory and recipes from design',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                onTap: () async {
                  await DatabaseHelper.instance.resetToSampleData();
                  await ref.read(foodListProvider.notifier).loadFoodItems();
                  await ref.read(shoppingListProvider.notifier).loadItems();
                  await ref.read(recipeListProvider.notifier).loadRecipes();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sample pantry data reseeded successfully!'),
                        backgroundColor: AppColors.primaryDark,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // About & Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F2ED),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Green Shelf (PantryPal)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 1.0.0 · Offline First & Privacy Safe\nAll your pantry data stays privately on your local device.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
