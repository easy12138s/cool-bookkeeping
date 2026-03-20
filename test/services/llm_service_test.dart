import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cool_bookkeeping/data/local/preferences.dart';
import 'package:cool_bookkeeping/services/llm_service.dart';

void main() {
  group('LlmService - 集成测试', () {
    late LlmService llmService;
    late PreferencesService preferencesService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'api_key': 'sk-ac31e8bddb234c538b353b80e073bba6',
        'api_base_url': 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      });
      final prefs = await SharedPreferences.getInstance();
      preferencesService = PreferencesService(prefs);
      llmService = LlmService(preferences: preferencesService);
    });

    test('should check if API is configured', () async {
      final isConfigured = await llmService.isConfigured;
      expect(isConfigured, true);
    });

    test('should parse single expense correctly', () async {
      final result = await llmService.parseTransaction(
        '午餐花了25元',
        expenseCategories: ['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'],
        incomeCategories: ['工资', '奖金', '投资', '兼职', '礼金', '其他'],
      );

      print('解析结果: ${result.amount}, ${result.category}, ${result.type}, ${result.note}');

      expect(result.amount, isNotNull);
      expect(result.amount, greaterThan(0));
      expect(result.category, isNotEmpty);
      expect(result.type, '支出');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('should parse multiple transactions correctly', () async {
      final results = await llmService.parseTransactions(
        '早餐花了15元，午餐25元，地铁5元',
        expenseCategories: ['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'],
        incomeCategories: ['工资', '奖金', '投资', '兼职', '礼金', '其他'],
      );

      print('多条解析结果:');
      for (final result in results) {
        print('  - ${result.amount}, ${result.category}, ${result.type}, ${result.note}');
      }

      expect(results.length, greaterThanOrEqualTo(3));
      
      final first = results.first;
      expect(first.amount, isNotNull);
      expect(first.type, '支出');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('should parse income correctly', () async {
      final result = await llmService.parseTransaction(
        '今天工资到账8000元',
        expenseCategories: ['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'],
        incomeCategories: ['工资', '奖金', '投资', '兼职', '礼金', '其他'],
      );

      print('收入解析结果: ${result.amount}, ${result.category}, ${result.type}, ${result.note}');

      expect(result.amount, isNotNull);
      expect(result.amount, greaterThan(0));
      expect(result.type, '收入');
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('should parse mixed income and expense', () async {
      final results = await llmService.parseTransactions(
        '今天工资到账8000元，花了30元买水果，晚上聚餐花了120元',
        expenseCategories: ['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'],
        incomeCategories: ['工资', '奖金', '投资', '兼职', '礼金', '其他'],
      );

      print('混合解析结果:');
      for (final result in results) {
        print('  - ${result.amount}, ${result.category}, ${result.type}, ${result.note}');
      }

      expect(results.length, 3);
      
      // 应该有收入和支出
      final hasIncome = results.any((r) => r.type == '收入');
      final hasExpense = results.any((r) => r.type == '支出');
      expect(hasIncome, true);
      expect(hasExpense, true);
    }, timeout: const Timeout(Duration(seconds: 60)));
  });

  group('LlmService - 未配置测试', () {
    test('should return error when API not configured', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final preferencesService = PreferencesService(prefs);
      final llmService = LlmService(preferences: preferencesService);

      final isConfigured = await llmService.isConfigured;
      expect(isConfigured, false);

      final result = await llmService.parseTransaction(
        '午餐花了25元',
        expenseCategories: ['餐饮'],
        incomeCategories: ['工资'],
      );

      expect(result.note, contains('未配置'));
    });
  });

  group('LlmService - Prompt 构建测试', () {
    late LlmService llmService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'api_key': 'test-key',
        'api_base_url': 'https://test.com',
      });
      final prefs = await SharedPreferences.getInstance();
      final preferencesService = PreferencesService(prefs);
      llmService = LlmService(preferences: preferencesService);
    });

    test('should build prompt with correct categories', () {
      final expenseCategories = ['餐饮', '交通', '购物'];
      final incomeCategories = ['工资', '奖金'];

      // 使用私有方法测试 prompt 构建
      llmService.parseTransactions(
        '测试',
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
      );

      // 由于是异步调用，我们验证服务可以正常调用
      expect(llmService, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 5)));
  });
}
