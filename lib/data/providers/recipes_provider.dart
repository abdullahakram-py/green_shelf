import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/string_normalizer.dart';
import '../models/food_item.dart';
import '../models/recipe.dart';
import '../repositories/recipe_repository.dart';
import 'food_provider.dart';

class RecipeMatch {
  final Recipe recipe;
  final int ownedCount;
  final int totalCount;
  final double matchRatio;
  final List<String> ownedIngredients;
  final List<String> missingIngredients;
  final bool hasExpiringIngredients;

  const RecipeMatch({
    required this.recipe,
    required this.ownedCount,
    required this.totalCount,
    required this.matchRatio,
    required this.ownedIngredients,
    required this.missingIngredients,
    required this.hasExpiringIngredients,
  });

  int get matchPercentage => (matchRatio * 100).round();
}

class RecipeListNotifier extends StateNotifier<AsyncValue<List<Recipe>>> {
  final RecipeRepository _repository;

  RecipeListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRecipes();
  }

  Future<void> loadRecipes() async {
    try {
      state = const AsyncValue.loading();
      final recipes = await _repository.getAllRecipes();
      state = AsyncValue.data(recipes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final recipeListProvider =
    StateNotifierProvider<RecipeListNotifier, AsyncValue<List<Recipe>>>((ref) {
  final repo = ref.watch(recipeRepositoryProvider);
  return RecipeListNotifier(repo);
});

final recipeSearchQueryProvider = StateProvider<String>((ref) => '');
final prioritizeExpiringProvider = StateProvider<bool>((ref) => true);

/// Matches and ranks recipes according to available pantry ingredients and expiry urgency
final matchedRecipesProvider = Provider<List<RecipeMatch>>((ref) {
  final recipesAsync = ref.watch(recipeListProvider);
  final foodAsync = ref.watch(foodListProvider);
  final searchQuery = ref.watch(recipeSearchQueryProvider).trim().toLowerCase();
  final prioritizeExpiring = ref.watch(prioritizeExpiringProvider);

  return recipesAsync.when(
    data: (recipes) {
      final List<FoodItem> pantryItems = foodAsync.asData?.value ?? [];
      final List<String> pantryNames =
          pantryItems.where((i) => !i.isExpired() && i.quantity > 0).map((i) => i.name).toList();

      final List<String> expiringSoonNames =
          pantryItems.where((i) => i.isExpiringSoon() && i.quantity > 0).map((i) => i.name).toList();

      List<RecipeMatch> matches = [];

      for (final recipe in recipes) {
        // Search filter
        if (searchQuery.isNotEmpty) {
          final matchesName = recipe.name.toLowerCase().contains(searchQuery);
          final matchesTag = recipe.tags?.toLowerCase().contains(searchQuery) ?? false;
          final matchesIng = recipe.ingredients.any((ing) => ing.toLowerCase().contains(searchQuery));
          if (!matchesName && !matchesTag && !matchesIng) continue;
        }

        final total = recipe.ingredients.length;
        if (total == 0) continue;

        List<String> owned = [];
        List<String> missing = [];
        bool usesExpiring = false;

        for (final ing in recipe.ingredients) {
          if (StringNormalizer.isIngredientMatched(ing, pantryNames)) {
            owned.add(ing);
            if (StringNormalizer.isIngredientMatched(ing, expiringSoonNames)) {
              usesExpiring = true;
            }
          } else {
            missing.add(ing);
          }
        }

        final ratio = owned.length / total;

        matches.add(RecipeMatch(
          recipe: recipe,
          ownedCount: owned.length,
          totalCount: total,
          matchRatio: ratio,
          ownedIngredients: owned,
          missingIngredients: missing,
          hasExpiringIngredients: usesExpiring,
        ));
      }

      // Sort by: 1) Expiring priority (if enabled), 2) Match ratio descending, 3) Prep time
      matches.sort((a, b) {
        if (prioritizeExpiring) {
          if (a.hasExpiringIngredients && !b.hasExpiringIngredients) return -1;
          if (!a.hasExpiringIngredients && b.hasExpiringIngredients) return 1;
        }
        final cmpRatio = b.matchRatio.compareTo(a.matchRatio);
        if (cmpRatio != 0) return cmpRatio;
        return a.recipe.prepMinutes.compareTo(b.recipe.prepMinutes);
      });

      return matches;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Spotlight "Cook tonight" recipe for home dashboard
final cookTonightRecipeProvider = Provider<RecipeMatch?>((ref) {
  final matches = ref.watch(matchedRecipesProvider);
  if (matches.isEmpty) return null;
  return matches.first;
});
