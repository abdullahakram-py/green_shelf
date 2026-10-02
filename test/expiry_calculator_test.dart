import 'package:flutter_test/flutter_test.dart';
import 'package:green_shelf/core/utils/expiry_calculator.dart';
import 'package:green_shelf/core/utils/string_normalizer.dart';

void main() {
  group('ExpiryCalculator Tests (TRD Section 2.5)', () {
    final now = DateTime(2026, 10, 1, 10, 0);

    test('Identifies expired item correctly', () {
      final pastDate = DateTime(2026, 9, 30);
      expect(ExpiryCalculator.statusFor(pastDate, now, 3), ExpiryStatus.expired);
    });

    test('Identifies today expiry correctly', () {
      final todayDate = DateTime(2026, 10, 1, 23, 59);
      expect(ExpiryCalculator.statusFor(todayDate, now, 3), ExpiryStatus.today);
    });

    test('Identifies expiring soon correctly', () {
      final tomorrow = DateTime(2026, 10, 2);
      final inThreeDays = DateTime(2026, 10, 4);
      expect(ExpiryCalculator.statusFor(tomorrow, now, 3), ExpiryStatus.soon);
      expect(ExpiryCalculator.statusFor(inThreeDays, now, 3), ExpiryStatus.soon);
    });

    test('Identifies fresh items correctly', () {
      final inFiveDays = DateTime(2026, 10, 6);
      final inSixMonths = DateTime(2027, 4, 1);
      expect(ExpiryCalculator.statusFor(inFiveDays, now, 3), ExpiryStatus.fresh);
      expect(ExpiryCalculator.statusFor(inSixMonths, now, 3), ExpiryStatus.fresh);
    });

    test('Formats human readable labels accurately', () {
      expect(ExpiryCalculator.formatExpiryLabel(DateTime(2026, 10, 1), now), 'Today');
      expect(ExpiryCalculator.formatExpiryLabel(DateTime(2026, 10, 2), now), 'Tomorrow');
      expect(ExpiryCalculator.formatExpiryLabel(DateTime(2026, 10, 3), now), '2 days');
      expect(ExpiryCalculator.formatExpiryLabel(DateTime(2026, 10, 6), now), '5 days');
      expect(ExpiryCalculator.formatExpiryLabel(DateTime(2026, 10, 22), now), '3 weeks');
      expect(ExpiryCalculator.formatExpiryLabel(DateTime(2027, 6, 1), now), '8 months');
    });
  });

  group('StringNormalizer & Recipe Matching Tests', () {
    test('Normalizes plural forms and synonyms correctly', () {
      expect(StringNormalizer.normalize('Tomatoes'), 'tomato');
      expect(StringNormalizer.normalize('Eggs'), 'egg');
      expect(StringNormalizer.normalize('Chicken Breast'), 'chicken');
      expect(StringNormalizer.normalize('Greek Yogurt'), 'yogurt');
      expect(StringNormalizer.normalize('Potatoes'), 'potato');
    });

    test('Correctly matches ingredient in pantry', () {
      final pantry = ['Farm Fresh Milk', 'Baby Spinach', 'Brown Eggs', 'Cheddar Cheese'];

      expect(StringNormalizer.isIngredientMatched('milk', pantry), isTrue);
      expect(StringNormalizer.isIngredientMatched('spinach', pantry), isTrue);
      expect(StringNormalizer.isIngredientMatched('egg', pantry), isTrue);
      expect(StringNormalizer.isIngredientMatched('cheese', pantry), isTrue);
      expect(StringNormalizer.isIngredientMatched('salmon', pantry), isFalse);
    });
  });
}
