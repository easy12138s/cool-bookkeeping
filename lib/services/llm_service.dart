import 'dart:convert';

import 'package:dio/dio.dart';

import '../data/local/preferences.dart';
import '../data/models/parsed_result.dart';

/// LLM 服务
/// 负责调用 OpenAI API 解析用户输入的记账内容
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

  /// 解析用户输入的记账内容
  /// [userInput] 用户输入的文本
  /// [expenseCategories] 支出类别列表
  /// [incomeCategories] 收入类别列表
  /// 返回解析结果 ParsedResult
  Future<ParsedResult> parseTransaction(
    String userInput, {
    required List<String> expenseCategories,
    required List<String> incomeCategories,
  }) async {
    if (!await isConfigured) {
      return ParsedResult(
        rawText: userInput,
        note: 'LLM 未配置，请先设置 API 密钥和基础 URL',
      );
    }

    final apiKey = await _preferences.getApiKey();
    final apiBaseUrl = await _preferences.getApiBaseUrl();

    final prompt = _buildPrompt(
      userInput: userInput,
      expenseCategories: expenseCategories,
      incomeCategories: incomeCategories,
    );

    try {
      final response = await _dio.post(
        '$apiBaseUrl/v1/chat/completions',
        data: {
          'model': 'gpt-3.5-turbo',
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
        return _parseResponse(content, userInput);
      } else {
        return _fallbackResult(userInput);
      }
    } on DioException catch (e) {
      return _fallbackResult(
        userInput,
        note: '请求失败: ${e.message}',
      );
    } catch (e) {
      return _fallbackResult(
        userInput,
        note: '解析错误: $e',
      );
    }
  }

  /// 系统提示词
  static const String _systemPrompt = '''你是一个智能语音记账助手。
你的任务是将用户的自然语言输入解析为结构化的记账数据。
请根据用户输入判断金额、类别、类型（收入/支出）、时间和备注。
返回结果必须是 JSON 格式。''';

  /// 构建用户提示词
  String _buildPrompt({
    required String userInput,
    required List<String> expenseCategories,
    required List<String> incomeCategories,
  }) {
    return '''请将以下记账内容解析为 JSON 格式：

用户输入: "$userInput"

可用支出类别: ${expenseCategories.join(', ')}
可用收入类别: ${incomeCategories.join(', ')}

请返回以下格式的 JSON：
{
  "amount": 金额数字（必填）,
  "category": "类别名称（从可用类别中选择，默认"其他"）",
  "type": "支出" 或 "收入"（默认"支出"）,
  "time": "ISO8601格式的时间字符串（可选，默认当前时间）",
  "note": "备注信息（可选）"
}

注意：
1. amount 必须是数字，不要带单位
2. category 必须从可用类别中选择，如果不确定就选"其他"
3. type 根据内容判断是收入还是支出
4. 只返回 JSON，不要有任何其他文字'''
        .trim();
  }

  /// 解析 API 响应
  ParsedResult _parseResponse(String content, String rawText) {
    try {
      // 清理可能的 markdown 代码块
      final cleanContent = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final json = jsonDecode(cleanContent) as Map<String, dynamic>;

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
    } catch (e) {
      return _fallbackResult(
        rawText,
        note: '无法解析 LLM 响应: $e',
      );
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
