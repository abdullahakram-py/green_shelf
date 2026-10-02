import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/db_helper.dart';
import '../models/recipe.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository();
});

class RecipeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Recipe>> getAllRecipes() async {
    final db = await _dbHelper.database;
    final maps = await db.query('recipes', orderBy: 'name ASC');
    return maps.map((e) => Recipe.fromMap(e)).toList();
  }

  Future<Recipe?> getRecipeById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('recipes', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Recipe.fromMap(maps.first);
  }

  Future<List<Recipe>> searchRecipes(String query) async {
    final db = await _dbHelper.database;
    final cleanQuery = '%${query.trim().toLowerCase()}%';
    final maps = await db.query(
      'recipes',
      where: 'LOWER(name) LIKE ? OR LOWER(ingredients) LIKE ? OR LOWER(tags) LIKE ?',
      whereArgs: [cleanQuery, cleanQuery, cleanQuery],
    );
    return maps.map((e) => Recipe.fromMap(e)).toList();
  }
}
