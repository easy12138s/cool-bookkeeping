import 'package:flutter_test/flutter_test.dart';
import 'package:cool_bookkeeping/data/models/parsed_result.dart';

void main() {
  group('ParsedResult', () {
    test('should create ParsedResult with default values', () {
      final result = ParsedResult(
        amount: 100.0,
        category: '餐饮',
        type: '支出',
      );

      expect(result.amount, 100.0);
      expect(result.category, '餐饮');
      expect(result.type, '支出');
      expect(result.note, isNull);
      expect(result.time, isNull);
      expect(result.rawText, isNull);
    });

    test('should create ParsedResult with all fields', () {
      final now = DateTime.now();
      final result = ParsedResult(
        amount: 250.50,
        category: '工资',
        type: '收入',
        time: now,
        note: '月薪',
        rawText: '今天工资到账 250.50 元',
      );

      expect(result.amount, 250.50);
      expect(result.category, '工资');
      expect(result.type, '收入');
      expect(result.time, now);
      expect(result.note, '月薪');
      expect(result.rawText, '今天工资到账 250.50 元');
    });

    test('should have default category as "其他"', () {
      final result = ParsedResult(amount: 100.0);
      expect(result.category, '其他');
    });

    test('should have default type as "支出"', () {
      final result = ParsedResult(amount: 100.0);
      expect(result.type, '支出');
    });

    test('should support JSON serialization', () {
      final result = ParsedResult(
        amount: 100.0,
        category: '餐饮',
        type: '支出',
        note: '午餐',
        rawText: '午餐花了 100 元',
      );

      final json = result.toJson();
      final fromJson = ParsedResult.fromJson(json);

      expect(fromJson.amount, result.amount);
      expect(fromJson.category, result.category);
      expect(fromJson.type, result.type);
      expect(fromJson.note, result.note);
      expect(fromJson.rawText, result.rawText);
    });

    test('should handle null amount', () {
      final result = ParsedResult(
        amount: null,
        category: '其他',
        type: '支出',
        note: '无法解析',
      );

      expect(result.amount, isNull);
    });

    test('should handle expense type correctly', () {
      final expenseResult = ParsedResult(
        amount: 50.0,
        category: '交通',
        type: '支出',
      );

      expect(expenseResult.type, '支出');
    });

    test('should handle income type correctly', () {
      final incomeResult = ParsedResult(
        amount: 5000.0,
        category: '工资',
        type: '收入',
      );

      expect(incomeResult.type, '收入');
    });
  });
}
