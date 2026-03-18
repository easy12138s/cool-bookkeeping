import 'package:flutter_test/flutter_test.dart';
import 'package:cool_bookkeeping/data/models/category_model.dart';

void main() {
  group('CategoryModel', () {
    test('should create CategoryModel with required fields', () {
      final category = CategoryModel(
        id: 'cat-1',
        name: '餐饮',
        icon: 'restaurant',
        type: 0,
        isPreset: true,
        isEnabled: true,
        sortOrder: 0,
      );

      expect(category.id, 'cat-1');
      expect(category.name, '餐饮');
      expect(category.icon, 'restaurant');
      expect(category.type, 0);
      expect(category.isPreset, true);
      expect(category.isEnabled, true);
      expect(category.sortOrder, 0);
    });

    test('should create CategoryModel with all fields', () {
      final category = CategoryModel(
        id: 'cat-2',
        name: '工资',
        icon: 'work',
        type: 1,
        isPreset: true,
        isEnabled: true,
        sortOrder: 1,
      );

      expect(category.id, 'cat-2');
      expect(category.name, '工资');
      expect(category.type, 1);
      expect(category.isPreset, true);
    });

    test('should support JSON serialization', () {
      final category = CategoryModel(
        id: 'cat-3',
        name: '交通',
        icon: 'directions_car',
        type: 0,
        isPreset: true,
        isEnabled: true,
        sortOrder: 2,
      );

      final json = category.toJson();
      final fromJson = CategoryModel.fromJson(json);

      expect(fromJson.id, category.id);
      expect(fromJson.name, category.name);
      expect(fromJson.icon, category.icon);
      expect(fromJson.type, category.type);
    });

    test('should correctly identify expense category (type=0)', () {
      final expenseCategory = CategoryModel(
        id: 'expense-cat',
        name: '购物',
        icon: 'shopping_bag',
        type: 0,
        isPreset: true,
        isEnabled: true,
        sortOrder: 0,
      );

      expect(expenseCategory.type, 0);
    });

    test('should correctly identify income category (type=1)', () {
      final incomeCategory = CategoryModel(
        id: 'income-cat',
        name: '奖金',
        icon: 'card_giftcard',
        type: 1,
        isPreset: true,
        isEnabled: true,
        sortOrder: 0,
      );

      expect(incomeCategory.type, 1);
    });

    test('should identify preset category', () {
      final presetCategory = CategoryModel(
        id: 'preset-cat',
        name: '预设分类',
        icon: 'category',
        type: 0,
        isPreset: true,
        isEnabled: true,
        sortOrder: 0,
      );

      expect(presetCategory.isPreset, true);
    });

    test('should identify custom category', () {
      final customCategory = CategoryModel(
        id: 'custom-cat',
        name: '自定义分类',
        icon: 'category',
        type: 0,
        isPreset: false,
        isEnabled: true,
        sortOrder: 100,
      );

      expect(customCategory.isPreset, false);
    });
  });
}
