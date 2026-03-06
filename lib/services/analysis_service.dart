import 'dart:convert';

import 'package:dio/dio.dart';

import '../data/local/preferences.dart';
import '../data/models/analysis_result.dart';
import '../data/models/category_model.dart';
import '../data/models/record_model.dart';

/// 智能分析服务
/// 负责调用 AI 分析月度消费数据
class AnalysisService {
  final PreferencesService _preferences;
  final Dio _dio;

  AnalysisService({
    required PreferencesService preferences,
    Dio? dio,
  })  : _preferences = preferences,
        _dio = dio ?? Dio();

  /// 检查 AI 是否已配置
  Future<bool> get isConfigured async {
    final apiKey = await _preferences.getApiKey();
    final apiBaseUrl = await _preferences.getApiBaseUrl();
    return apiKey != null &&
        apiKey.isNotEmpty &&
        apiBaseUrl != null &&
        apiBaseUrl.isNotEmpty;
  }

  /// 分析月度消费情况
  /// [records] 该月的所有记账记录
  /// [categories] 所有分类信息
  /// [year] 年份
  /// [month] 月份
  Future<AnalysisResult> analyzeMonthlySpending({
    required List<RecordModel> records,
    required List<CategoryModel> categories,
    required int year,
    required int month,
  }) async {
    if (!await isConfigured) {
      throw Exception('AI 未配置，请先设置 API 密钥和基础 URL');
    }

    // 计算统计数据
    final totalExpense = records
        .where((r) => r.type == 0)
        .fold<double>(0, (sum, r) => sum + r.amount);
    final totalIncome = records
        .where((r) => r.type == 1)
        .fold<double>(0, (sum, r) => sum + r.amount);

    // 按类别统计
    final categoryStats = _calculateCategoryStats(records, categories);

    // 构建提示词
    final prompt = _buildAnalysisPrompt(
      year: year,
      month: month,
      totalExpense: totalExpense,
      totalIncome: totalIncome,
      categoryStats: categoryStats,
    );

    try {
      final apiKey = await _preferences.getApiKey();
      final apiBaseUrl = await _preferences.getApiBaseUrl();

      final response = await _dio.post(
        '$apiBaseUrl/v1/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.5,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return _parseAnalysisResponse(content);
      } else {
        throw Exception('API 请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('网络请求失败: ${e.message}');
    } catch (e) {
      throw Exception('分析失败: $e');
    }
  }

  /// 系统提示词
  static const String _systemPrompt = '''你是一个专业的个人财务分析助手。
你的任务是根据用户的月度消费数据，提供全面、专业、有洞察力的消费分析。
分析应该客观、实用，并给出具体的建议。
返回结果必须是 JSON 格式。''';

  /// 构建分析提示词
  String _buildAnalysisPrompt({
    required int year,
    required int month,
    required double totalExpense,
    required double totalIncome,
    required List<CategoryStat> categoryStats,
  }) {
    final expenseStats = categoryStats.where((s) => s.type == 0).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final incomeStats = categoryStats.where((s) => s.type == 1).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final buffer = StringBuffer();
    buffer.writeln('请分析以下 ${year}年${month}月 的消费数据：\n');
    buffer.writeln('【基础数据】');
    buffer.writeln('总支出: ¥${totalExpense.toStringAsFixed(2)}');
    buffer.writeln('总收入: ¥${totalIncome.toStringAsFixed(2)}');
    buffer.writeln('结余: ¥${(totalIncome - totalExpense).toStringAsFixed(2)}');
    buffer.writeln('储蓄率: ${totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100).toStringAsFixed(1) : 0}%\n');

    if (expenseStats.isNotEmpty) {
      buffer.writeln('【支出类别明细】');
      for (final stat in expenseStats) {
        buffer.writeln('${stat.categoryName}: ¥${stat.amount.toStringAsFixed(2)} (${(stat.percentage * 100).toStringAsFixed(1)}%)');
      }
      buffer.writeln();
    }

    if (incomeStats.isNotEmpty) {
      buffer.writeln('【收入类别明细】');
      for (final stat in incomeStats) {
        buffer.writeln('${stat.categoryName}: ¥${stat.amount.toStringAsFixed(2)} (${(stat.percentage * 100).toStringAsFixed(1)}%)');
      }
      buffer.writeln();
    }

    buffer.writeln('请从以下维度进行分析：');
    buffer.writeln('1. 消费概况：总体消费水平和收支平衡情况');
    buffer.writeln('2. 类别分析：主要消费领域和异常消费');
    buffer.writeln('3. 消费建议：基于数据的省钱建议和优化方案');
    buffer.writeln('4. 趋势洞察：与常规消费模式的对比');
    buffer.writeln('5. 下月预测：基于历史数据的消费预测');
    buffer.writeln('6. 健康评分：给出 0-100 的消费健康评分\n');

    buffer.writeln('请以 JSON 格式返回，不要包含任何 markdown 代码块标记：');
    buffer.writeln('''
{
  "summary": "总体评价（1-2句话，简洁有力）",
  "overview": "消费概况分析（2-3句话）",
  "categoryAnalysis": "类别消费分析（指出主要消费领域和异常）",
  "suggestions": ["建议1", "建议2", "建议3"],
  "trends": "趋势洞察（与常规模式对比）",
  "prediction": "下月消费预测",
  "score": 75
}''');

    return buffer.toString();
  }

  /// 计算类别统计
  List<CategoryStat> _calculateCategoryStats(
    List<RecordModel> records,
    List<CategoryModel> categories,
  ) {
    final Map<String, double> expenseMap = {};
    final Map<String, double> incomeMap = {};

    for (final record in records) {
      if (record.type == 0) {
        expenseMap[record.categoryId] =
            (expenseMap[record.categoryId] ?? 0) + record.amount;
      } else {
        incomeMap[record.categoryId] =
            (incomeMap[record.categoryId] ?? 0) + record.amount;
      }
    }

    final totalExpense = expenseMap.values.fold<double>(0, (sum, v) => sum + v);
    final totalIncome = incomeMap.values.fold<double>(0, (sum, v) => sum + v);

    final stats = <CategoryStat>[];

    // 支出统计
    for (final entry in expenseMap.entries) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => CategoryModel(
          id: entry.key,
          name: '未知',
          icon: 'help',
          type: 0,
          isPreset: false,
          isEnabled: true,
          sortOrder: 0,
        ),
      );
      stats.add(CategoryStat(
        categoryName: category.name,
        amount: entry.value,
        percentage: totalExpense > 0 ? entry.value / totalExpense : 0,
        type: 0,
      ));
    }

    // 收入统计
    for (final entry in incomeMap.entries) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => CategoryModel(
          id: entry.key,
          name: '未知',
          icon: 'help',
          type: 1,
          isPreset: false,
          isEnabled: true,
          sortOrder: 0,
        ),
      );
      stats.add(CategoryStat(
        categoryName: category.name,
        amount: entry.value,
        percentage: totalIncome > 0 ? entry.value / totalIncome : 0,
        type: 1,
      ));
    }

    return stats;
  }

  /// 解析分析响应
  AnalysisResult _parseAnalysisResponse(String content) {
    try {
      // 清理可能的 markdown 代码块
      final cleanContent = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final json = jsonDecode(cleanContent) as Map<String, dynamic>;

      // 解析建议列表
      final suggestions = (json['suggestions'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [];

      return AnalysisResult(
        summary: json['summary'] as String? ?? '暂无分析',
        overview: json['overview'] as String? ?? '',
        categoryAnalysis: json['categoryAnalysis'] as String? ?? '',
        suggestions: suggestions,
        trends: json['trends'] as String? ?? '',
        prediction: json['prediction'] as String? ?? '',
        score: (json['score'] as num?)?.toInt() ?? 50,
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('解析 AI 响应失败: $e');
    }
  }
}