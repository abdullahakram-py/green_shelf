class StringNormalizer {
  StringNormalizer._();

  static final Map<String, String> _synonyms = {
    'tomatoes': 'tomato',
    'eggs': 'egg',
    'potatoes': 'potato',
    'onions': 'onion',
    'carrots': 'carrot',
    'apples': 'apple',
    'bananas': 'banana',
    'lemons': 'lemon',
    'limes': 'lemon',
    'bell peppers': 'bell pepper',
    'peppers': 'bell pepper',
    'capsicum': 'bell pepper',
    'cheeses': 'cheese',
    'cheddar': 'cheese',
    'mozzarella': 'cheese',
    'parmesan': 'cheese',
    'cow milk': 'milk',
    'whole milk': 'milk',
    'fresh milk': 'milk',
    'chicken breast': 'chicken',
    'chicken thighs': 'chicken',
    'chicken fillet': 'chicken',
    'greek yogurt': 'yogurt',
    'curd': 'yogurt',
    'white rice': 'rice',
    'brown rice': 'rice',
    'basmati rice': 'rice',
    'cooked rice': 'rice',
    'pasta noodles': 'pasta',
    'spaghetti': 'pasta',
    'penne': 'pasta',
    'baby spinach': 'spinach',
    'garlic cloves': 'garlic',
    'garlic powder': 'garlic',
    'unsalted butter': 'butter',
    'extra virgin olive oil': 'olive oil',
    'cooking oil': 'olive oil',
    'beef strips': 'beef',
    'ground beef': 'beef',
    'minced beef': 'beef',
    'steak': 'beef',
    'salmon fillet': 'salmon',
    'fresh salmon': 'salmon',
    'cucumber slices': 'cucumber',
  };

  /// Normalizes an ingredient name for flexible matching
  static String normalize(String input) {
    var text = input.trim().toLowerCase();

    // Remove punctuation
    text = text.replaceAll(RegExp(r'[^\w\s]'), '');

    // Check direct synonyms
    if (_synonyms.containsKey(text)) {
      return _synonyms[text]!;
    }

    // Check partial contains in synonyms
    for (final entry in _synonyms.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }

    // Basic singularization
    if (text.endsWith('ies')) {
      text = '${text.substring(0, text.length - 3)}y';
    } else if (text.endsWith('es') && !text.endsWith('cheese')) {
      text = text.substring(0, text.length - 2);
    } else if (text.endsWith('s') && !text.endsWith('ss') && text != 'rice' && text != 'hummus') {
      text = text.substring(0, text.length - 1);
    }

    return text.trim();
  }

  /// Checks if an ingredient is matched in a list of available pantry ingredients
  static bool isIngredientMatched(String recipeIngredient, List<String> availableItems) {
    final normalizedRecipeIng = normalize(recipeIngredient);

    for (final item in availableItems) {
      final normalizedPantryItem = normalize(item);
      if (normalizedRecipeIng == normalizedPantryItem ||
          normalizedPantryItem.contains(normalizedRecipeIng) ||
          normalizedRecipeIng.contains(normalizedPantryItem)) {
        return true;
      }
    }
    return false;
  }
}
