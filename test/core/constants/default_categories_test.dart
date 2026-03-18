import 'package:flutter_test/flutter_test.dart';
import 'package:cool_bookkeeping/core/constants/default_categories.dart';

void main() {
  group('DefaultCategories', () {
    test('should have non-empty category list', () {
      expect(DefaultCategories.allCategories, isNotEmpty);
    });

    test('should have correct number of expense categories', () {
      final expenseCategories = DefaultCategories.allCategories
          .where((c) => c['type'] == 0)
          .toList();
      expect(expenseCategories.length, greaterThan(0));
    });

    test('should have correct number of income categories', () {
      final incomeCategories = DefaultCategories.allCategories
          .where((c) => c['type'] == 1)
          .toList();
      expect(incomeCategories.length, greaterThan(0));
    });

    test('all categories should have required fields', () {
      for (final category in DefaultCategories.allCategories) {
        expect(category.containsKey('name'), true,
            reason: 'Category should have name field');
        expect(category.containsKey('icon'), true,
            reason: 'Category should have icon field');
        expect(category.containsKey('type'), true,
            reason: 'Category should have type field');
      }
    });

    test('all category names should be non-empty', () {
      for (final category in DefaultCategories.allCategories) {
        expect(category['name'], isNotEmpty,
            reason: 'Category name should not be empty');
      }
    });

    test('all category icons should be non-empty', () {
      for (final category in DefaultCategories.allCategories) {
        expect(category['icon'], isNotEmpty,
            reason: 'Category icon should not be empty');
      }
    });

    test('all category types should be valid (0=expense, 1=income)', () {
      for (final category in DefaultCategories.allCategories) {
        final type = category['type'] as int;
        expect(type == 0 || type == 1, true,
            reason: 'Category type should be 0 or 1');
      }
    });

    test('expense categories should have type=0', () {
      final expenseCategories = DefaultCategories.allCategories
          .where((c) => c['type'] == 0)
          .toList();

      for (final category in expenseCategories) {
        expect(category['type'], 0);
      }
    });

    test('income categories should have type=1', () {
      final incomeCategories = DefaultCategories.allCategories
          .where((c) => c['type'] == 1)
          .toList();

      for (final category in incomeCategories) {
        expect(category['type'], 1);
      }
    });

    test('should contain common expense categories', () {
      final categoryNames = DefaultCategories.allCategories
          .map((c) => c['name'] as String)
          .toList();

      expect(categoryNames.contains('餐饮'), true);
      expect(categoryNames.contains('交通'), true);
      expect(categoryNames.contains('购物'), true);
    });

    test('should contain common income categories', () {
      final categoryNames = DefaultCategories.allCategories
          .map((c) => c['name'] as String)
          .toList();

      expect(categoryNames.contains('工资'), true);
      expect(categoryNames.contains('奖金'), true);
    });

    test('should have unique category names within same type', () {
      final expenseCategories = DefaultCategories.allCategories
          .where((c) => c['type'] == 0)
          .map((c) => c['name'] as String)
          .toList();
      final uniqueExpenseNames = expenseCategories.toSet();

      final incomeCategories = DefaultCategories.allCategories
          .where((c) => c['type'] == 1)
          .map((c) => c['name'] as String)
          .toList();
      final uniqueIncomeNames = incomeCategories.toSet();

      expect(expenseCategories.length, uniqueExpenseNames.length,
          reason: 'Expense category names should be unique');
      expect(incomeCategories.length, uniqueIncomeNames.length,
          reason: 'Income category names should be unique');
    });
  });
}
