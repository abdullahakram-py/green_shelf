import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_helpers.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/food_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/summary_card.dart';
import '../../data/models/food_item.dart';
import '../../data/providers/food_provider.dart';
import '../../data/providers/recipes_provider.dart';
import 'widgets/hero_alert_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final stats = ref.watch(dashboardStatsProvider);
    final foodAsync = ref.watch(foodListProvider);
    final useTheseFirst = ref.watch(useTheseFirstItemsProvider);
    final cookTonight = ref.watch(cookTonightRecipeProvider);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: foodAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryDark),
          ),
          error: (err, _) => Center(
            child: Text('Failed to load dashboard: $err'),
          ),
          data: (allItems) {
            if (allItems.isEmpty) {
              return EmptyStateView(
                icon: Icons.kitchen_outlined,
                title: 'Your pantry is empty',
                description: 'Add grocery items to track expiry dates and get recipe ideas.',
                buttonText: 'Add your first grocery',
                onButtonPressed: () => context.push('/add-food'),
              );
            }

            final expiringItems = allItems.where((i) => i.isExpiringSoon()).toList();

            return RefreshIndicator(
              color: AppColors.primaryDark,
              onRefresh: () async {
                await ref.read(foodListProvider.notifier).loadFoodItems();
                await ref.read(recipeListProvider.notifier).loadRecipes();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateHelpers.formatHeaderDate(now),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateHelpers.getGreeting(now),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (isTablet) ...[
                              ElevatedButton.icon(
                                onPressed: () => context.push('/add-food'),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add food'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            IconButton(
                              onPressed: () => context.push('/settings'),
                              icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary, size: 22),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF3F2ED),
                                shape: const CircleBorder(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Hero "Needs Attention" Card
                    if (!isTablet) ...[
                      HeroAlertCard(
                        expiringItems: expiringItems,
                        onViewAlerts: () {
                          context.push('/alerts');
                        },
                      ),
                      const SizedBox(height: 20),
                    ],

                    // $2 \times 2$ Grid Metrics
                    _buildMetricsGrid(context, ref, stats, isTablet),
                    const SizedBox(height: 24),

                    // Wide Layout (Tablet): Split "Use these first" and "Cook Tonight"
                    if (isTablet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildUseTheseFirstSection(context, ref, useTheseFirst),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                HeroAlertCard(
                                  expiringItems: expiringItems,
                                  onViewAlerts: () => context.push('/alerts'),
                                ),
                                const SizedBox(height: 16),
                                if (cookTonight != null)
                                  _buildCookTonightCard(context, cookTonight),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      // Mobile Layout: "Use these first" List
                      _buildUseTheseFirstSection(context, ref, useTheseFirst),
                      const SizedBox(height: 20),

                      // Mobile Layout: "Cook tonight" card
                      if (cookTonight != null) ...[
                        _buildCookTonightCard(context, cookTonight),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
    bool isTablet,
  ) {
    void navigateToPantryWithFilter({String? status, String? location}) {
      ref.read(pantryFilterProvider.notifier).state = PantryFilterState(
        statusFilter: status ?? 'all',
        locationFilter: location ?? 'All',
      );
      // Navigate to Pantry tab (route '/pantry')
      context.go('/pantry');
    }

    final totalCard = SummaryCard(
      title: 'Total items',
      count: stats.totalItems,
      onTap: () => navigateToPantryWithFilter(status: 'all'),
    );

    final expiringCard = SummaryCard(
      title: 'Expiring soon',
      count: stats.expiringSoonCount,
      countColor: stats.expiringSoonCount > 0 ? const Color(0xFFB45309) : null,
      onTap: () => navigateToPantryWithFilter(status: 'soon'),
    );

    final expiredCard = SummaryCard(
      title: 'Expired',
      count: stats.expiredCount,
      countColor: stats.expiredCount > 0 ? AppColors.statusExpired : null,
      onTap: () => navigateToPantryWithFilter(status: 'expired'),
    );

    final lowStockCard = SummaryCard(
      title: 'Low stock',
      count: stats.lowStockCount,
      countColor: stats.lowStockCount > 0 ? AppColors.secondary : null,
      onTap: () => navigateToPantryWithFilter(status: 'low_stock'),
    );

    if (isTablet) {
      return Row(
        children: [
          Expanded(child: totalCard),
          const SizedBox(width: 12),
          Expanded(child: expiringCard),
          const SizedBox(width: 12),
          Expanded(child: expiredCard),
          const SizedBox(width: 12),
          Expanded(child: lowStockCard),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: totalCard),
            const SizedBox(width: 12),
            Expanded(child: expiringCard),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: expiredCard),
            const SizedBox(width: 12),
            Expanded(child: lowStockCard),
          ],
        ),
      ],
    );
  }

  Widget _buildUseTheseFirstSection(
    BuildContext context,
    WidgetRef ref,
    List<FoodItem> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Use these first',
          actionTitle: 'See all',
          padding: EdgeInsets.zero,
          onActionTap: () {
            ref.read(pantryFilterProvider.notifier).state = const PantryFilterState();
            context.go('/pantry');
          },
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return FoodCard(
              item: item,
              onTap: () => context.push('/food-details/${item.id}'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCookTonightCard(BuildContext context, RecipeMatch match) {
    final recipe = match.recipe;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withAlpha(45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cook tonight',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${match.matchPercentage}% match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recipe.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            match.missingIngredients.isEmpty
                ? 'You have all ${match.totalCount} ingredients in your pantry!'
                : 'You have ${match.ownedCount} of ${match.totalCount} ingredients. Missing: ${match.missingIngredients.first}.',
            style: TextStyle(
              color: Colors.white.withAlpha(220),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/recipe-details/${recipe.id}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3F2ED),
              foregroundColor: AppColors.primaryDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'See recipe',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
