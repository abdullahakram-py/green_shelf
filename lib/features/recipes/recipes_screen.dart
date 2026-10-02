import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/recipe_card.dart';
import '../../data/providers/recipes_provider.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Breakfast',
    'Dinner',
    'Soup',
    'Salad',
    'Snacks',
    'Dessert',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchedRecipes = ref.watch(matchedRecipesProvider);
    final prioritizeExpiring = ref.watch(prioritizeExpiringProvider);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 720;

    // Filter by Category
    final displayedRecipes = matchedRecipes.where((m) {
      if (_selectedCategory == 'All') return true;
      return (m.recipe.category ?? '').toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipe Ideas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Cook delicious meals using what you already have',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 20,
                vertical: 8,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(recipeSearchQueryProvider.notifier).state = val;
                },
                decoration: InputDecoration(
                  hintText: 'Search recipe name or ingredient...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textTertiary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(recipeSearchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Prioritize Expiring Switch Banner
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 32 : 20,
                vertical: 4,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F2ED),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 20, color: AppColors.primaryDark),
                        SizedBox(width: 8),
                        Text(
                          'Prioritize expiring items',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Switch.adaptive(
                      value: prioritizeExpiring,
                      activeTrackColor: AppColors.primaryDark,
                      activeThumbColor: Colors.white,
                      onChanged: (val) {
                        ref.read(prioritizeExpiringProvider.notifier).state = val;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Categories horizontal bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 20),
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryDark : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryDark : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Recipe Cards List
            Expanded(
              child: displayedRecipes.isEmpty
                  ? const EmptyStateView(
                      icon: Icons.menu_book_outlined,
                      title: 'No recipes found',
                      description: 'Try modifying your search keywords or add more pantry items.',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 32 : 20,
                        vertical: 8,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: displayedRecipes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final match = displayedRecipes[index];
                        return RecipeCard(
                          match: match,
                          onTap: () {
                            context.push('/recipe-details/${match.recipe.id}');
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
}
