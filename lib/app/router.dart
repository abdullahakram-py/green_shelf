import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/responsive_scaffold.dart';
import '../data/models/food_item.dart';
import '../features/alerts/alerts_screen.dart';
import '../features/home/home_screen.dart';
import '../features/pantry/add_edit_food_screen.dart';
import '../features/pantry/food_details_screen.dart';
import '../features/pantry/pantry_screen.dart';
import '../features/recipes/recipe_details_screen.dart';
import '../features/recipes/recipes_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shopping/shopping_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ResponsiveScaffold(navigationShell: navigationShell);
      },
      branches: [
        // 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // 1: Pantry
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pantry',
              builder: (context, state) => const PantryScreen(),
            ),
          ],
        ),

        // 2: Alerts
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/alerts',
              builder: (context, state) => const AlertsScreen(),
            ),
          ],
        ),

        // 3: Recipes
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => const RecipesScreen(),
            ),
          ],
        ),

        // 4: Shopping List
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shop',
              builder: (context, state) => const ShoppingScreen(),
            ),
          ],
        ),
      ],
    ),

    // Top-Level Screens
    GoRoute(
      path: '/add-food',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final prefill = state.extra as FoodItem?;
        return AddEditFoodScreen(
          itemToEdit: null,
          initialName: prefill?.name,
          initialQuantity: prefill?.quantity,
          initialUnit: prefill?.unit,
          initialCategory: prefill?.category,
        );
      },
    ),
    GoRoute(
      path: '/edit-food',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final item = state.extra as FoodItem?;
        return AddEditFoodScreen(itemToEdit: item);
      },
    ),
    GoRoute(
      path: '/food-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        return FoodDetailsScreen(itemId: id);
      },
    ),
    GoRoute(
      path: '/recipe-details/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final idStr = state.pathParameters['id'] ?? '0';
        final id = int.tryParse(idStr) ?? 0;
        return RecipeDetailsScreen(recipeId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
