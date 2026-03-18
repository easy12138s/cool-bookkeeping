import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/local/preferences.dart';
import '../data/models/parsed_result.dart';

/// LLM 服务
/// 负责调用 OpenAI API 解析用户输入的记账内容
/// 支持单条和多条记账解析
class LlmService {
  final PreferencesService _preferences;
  final Dio _dio;

  LlmService({
    required PreferencesService preferences,
    Dio? dio,
  })  : _preferences = preferences,
        _dio = dio ?? Dio();

  /// 检查 LLM 是否已配置
  /// 需要 apiKey 和 apiBaseUrl 都已设置
  Future<bool> get isConfigured async {
    final apiKey = await _preferences.getApiKey();
    final apiBaseUrl = await _preferences.getApiBaseUrl();
    return apiKey != null &&
        apiKey.isNotEmpty &&
        apiBaseUrl != null &&
        apiBaseUrl.isNotEmpty;
  }

  /// 解析用户输入的记账内容（单条，向后兼容）
  /// [userInput] 用户输入的文本
  /// [expenseCategories] 支出类别列表
  /// [incomeCategories] 收入类别列表
  /// 返回解析结果 ParsedResult
  Future<ParsedResult> parseTransaction(
    String userInput, {
    required List<String> expenseCategories,
    required List<String> incomeCategories,
  }) async {
    final results = await parseTransactions(
      userInput,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );
    
    if (results.isNotEmpty) {
      return results.first;
    }
    
    return _fallbackResult(userInput);
  }

  /// 解析用户输入的记账内容（支持多条）
  /// [userInput] 用户输入的文本
  /// [expenseCategories] 支出类别列表
  /// [incomeCategories] 收入类别列表
  /// 返回解析结果列表 List<ParsedResult>
  Future<List<ParsedResult>> parseTransactions(
    String userInput, {
    required List<String> expenseCategories,
    required List<String> incomeCategories,
  }) async {
    if (!await isConfigured) {
      return [
        ParsedResult(
          rawText: userInput,
          note: 'LLM 未配置，请先设置 API 密钥和基础 URL',
        )
      ];
    }

    final apiKey = await _preferences.getApiKey();
    final apiBaseUrl = await _preferences.getApiBaseUrl();
    final modelName = await _preferences.getModelName();

    final prompt = _buildBatchPrompt(
      userInput: userInput,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );

    try {
      final response = await _dio.post(
        '$apiBaseUrl/chat/completions',
        data: {
          'model': modelName,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return _parseBatchResponse(content, userInput);
      } else {
        return [_fallbackResult(userInput)];
      }
    } on DioException catch (e) {
      return [
        _fallbackResult(
          userInput,
          note: '请求失败: ${e.message}',
        )
      ];
    } catch (e) {
      return [
        _fallbackResult(
          userInput,
          note: '解析错误: $e',
        )
      ];
    }
  }

  /// 系统提示词
  static const String _systemPrompt = '''你是一个智能语音记账助手。
你的任务是将用户的自然语言输入解析为结构化的记账数据。
请根据用户输入判断金额、类别、类型（收入/支出）、时间和备注。
支持识别多条记账记录。
返回结果必须是 JSON 格式。''';

  /// 构建批量解析提示词
  String _buildBatchPrompt({
    required String userInput,
    required List<String> expenseCategories,
    required List<String> incomeCategories,
  }) {
    return '''请识别用户输入中的所有记账记录，返回 JSON 数组格式。

## 示例 1

输入: "早餐花了15元，午餐25元，地铁5元"
输出:
[
  {
    "amount": 15,
    "category": "餐饮",
    "type": "支出",
    "note": "早餐"
  },
  {
    "amount": 25,
    "category": "餐饮",
    "type": "支出",
    "note": "午餐"
  },
  {
    "amount": 5,
    "category": "交通",
    "type": "支出",
    "note": "地铁"
  }
]

## 示例 2

输入: "今天工资到账8000元，花了30元买水果，晚上聚餐花了120元"
输出:
[
  {
    "amount": 8000,
    "category": "工资",
    "type": "收入",
    "note": "工资到账"
  },
  {
    "amount": 30,
    "category": "餐饮",
    "type": "支出",
    "note": "买水果"
  },
  {
    "amount": 120,
    "category": "餐饮",
    "type": "支出",
    "note": "聚餐"
  }
]

## 可用类别

支出类别: ${expenseCategories.join(', ')}
收入类别: ${incomeCategories.join(', ')}

## 要求

1. 识别输入中的所有记账记录
2. 返回 JSON 数组格式，即使只有一条记录也要用数组
3. 类别必须从可用类别中选择，没有明确类别的默认"其他"
4. 类型只能是"支出"或"收入"，默认"支出"
5. note 字段提取关键描述信息
6. amount 必须是数字，不要带单位
7. 只返回 JSON 数组，不要有任何其他文字

请解析以下输入：
"$userInput"'''.trim();
  }

  /// 解析批量 API 响应
  List<ParsedResult> _parseBatchResponse(String content, String rawText) {
    try {
      // 清理可能的 markdown 代码块
      final cleanContent = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final dynamic decoded = jsonDecode(cleanContent);
      
      // 处理数组格式
      if (decoded is List) {
        return decoded.map((json) {
          if (json is Map<String, dynamic>) {
            return ParsedResult(
              amount: json['amount'] != null
                  ? (json['amount'] as num).toDouble()
                  : null,
              category: json['category'] as String? ?? '其他',
              type: json['type'] as String? ?? '支出',
              time: json['time'] != null ? DateTime.tryParse(json['time']) : null,
              note: json['note'] as String?,
              rawText: rawText,
            );
          }
          return _fallbackResult(rawText);
        }).toList();
      }
      
      // 处理单条对象格式（向后兼容）
      if (decoded is Map<String, dynamic>) {
        return [
          ParsedResult(
            amount: decoded['amount'] != null
                ? (decoded['amount'] as num).toDouble()
                : null,
            category: decoded['category'] as String? ?? '其他',
            type: decoded['type'] as String? ?? '支出',
            time: decoded['time'] != null ? DateTime.tryParse(decoded['time']) : null,
            note: decoded['note'] as String?,
            rawText: rawText,
          )
        ];
      }
      
      return [_fallbackResult(rawText, note: '无法解析 LLM 响应格式')];
    } catch (e) {
      if (kDebugMode) {
        print('Parse batch response error: $e');
        print('Content: $content');
      }
      return [
        _fallbackResult(
          rawText,
          note: '无法解析 LLM 响应: $e',
        )
      ];
    }
  }

  /// 降级结果
  ParsedResult _fallbackResult(String rawText, {String? note}) {
    return ParsedResult(
      rawText: rawText,
      note: note ?? '解析失败，请手动输入',
    );
  }
}
