import 'dart:convert';

class RecipeIngredientQty {
  final String name;
  final String amount;

  const RecipeIngredientQty({
    required this.name,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'amount': amount,
      };

  factory RecipeIngredientQty.fromMap(Map<String, dynamic> map) {
    return RecipeIngredientQty(
      name: map['name'] as String? ?? '',
      amount: map['amount'] as String? ?? '',
    );
  }
}

class Recipe {
  final int? id;
  final String name;
  final String? category;
  final int prepMinutes;
  final String difficulty;
  final String? imageUrl;
  final List<String> ingredients;
  final List<RecipeIngredientQty> ingredientsWithQty;
  final List<String> instructions;
  final String? tags;

  const Recipe({
    this.id,
    required this.name,
    this.category,
    required this.prepMinutes,
    this.difficulty = 'Easy',
    this.imageUrl,
    required this.ingredients,
    this.ingredientsWithQty = const [],
    required this.instructions,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'category': category,
      'prep_minutes': prepMinutes,
      'difficulty': difficulty,
      'image_url': imageUrl,
      'ingredients': jsonEncode(ingredients),
      'ingredients_with_qty':
          jsonEncode(ingredientsWithQty.map((e) => e.toMap()).toList()),
      'instructions': jsonEncode(instructions),
      'tags': tags,
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map) {
    List<String> parsedIngredients = [];
    if (map['ingredients'] != null) {
      if (map['ingredients'] is String) {
        final decoded = jsonDecode(map['ingredients'] as String);
        if (decoded is List) {
          parsedIngredients = decoded.map((e) => e.toString()).toList();
        }
      } else if (map['ingredients'] is List) {
        parsedIngredients =
            (map['ingredients'] as List).map((e) => e.toString()).toList();
      }
    }

    List<RecipeIngredientQty> parsedQty = [];
    if (map['ingredients_with_qty'] != null) {
      try {
        dynamic decoded = map['ingredients_with_qty'];
        if (decoded is String) {
          decoded = jsonDecode(decoded);
        }
        if (decoded is List) {
          parsedQty = decoded
              .map((e) => RecipeIngredientQty.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {}
    }

    List<String> parsedInstructions = [];
    if (map['instructions'] != null) {
      if (map['instructions'] is String) {
        final decoded = jsonDecode(map['instructions'] as String);
        if (decoded is List) {
          parsedInstructions = decoded.map((e) => e.toString()).toList();
        }
      } else if (map['instructions'] is List) {
        parsedInstructions =
            (map['instructions'] as List).map((e) => e.toString()).toList();
      }
    }

    return Recipe(
      id: map['id'] as int?,
      name: map['name'] as String,
      category: map['category'] as String?,
      prepMinutes: map['prep_minutes'] as int? ?? 15,
      difficulty: map['difficulty'] as String? ?? 'Easy',
      imageUrl: map['image_url'] as String?,
      ingredients: parsedIngredients,
      ingredientsWithQty: parsedQty,
      instructions: parsedInstructions,
      tags: map['tags'] as String?,
    );
  }
}
