import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_result.freezed.dart';
part 'parsed_result.g.dart';

/// 解析结果数据模型
/// 用于存储 LLM 解析后的记账数据
@freezed
class ParsedResult with _$ParsedResult {
  const factory ParsedResult({
    /// 金额
    double? amount,

    /// 类别名称，默认"其他"
    @Default('其他') String category,

    /// 类型，默认"支出"
    @Default('支出') String type,

    /// 时间
    DateTime? time,

    /// 备注
    String? note,

    /// 原始输入文本
    String? rawText,
  }) = _ParsedResult;

  /// 从 JSON 反序列化
  factory ParsedResult.fromJson(Map<String, Object?> json) =>
      _$ParsedResultFromJson(json);
}
