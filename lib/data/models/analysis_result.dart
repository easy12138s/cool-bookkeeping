import 'package:freezed_annotation/freezed_annotation.dart';

part 'analysis_result.freezed.dart';
part 'analysis_result.g.dart';

/// 智能分析结果模型
/// 存储 AI 对月度消费数据的分析结果
@freezed
class AnalysisResult with _$AnalysisResult {
  const factory AnalysisResult({
    /// 总体评价（1-2句话总结）
    required String summary,

    /// 消费概况分析
    required String overview,

    /// 类别消费分析
    required String categoryAnalysis,

    /// 智能建议列表
    required List<String> suggestions,

    /// 趋势洞察
    required String trends,

    /// 下月消费预测
    required String prediction,

    /// 消费健康评分（0-100）
    required int score,

    /// 分析时间戳
    required DateTime analyzedAt,
  }) = _AnalysisResult;

  /// 从 JSON 反序列化
  factory AnalysisResult.fromJson(Map<String, Object?> json) =>
      _$AnalysisResultFromJson(json);
}

/// 分析请求模型
/// 用于向 AI 发送分析请求时的数据结构
class AnalysisRequest {
  final int year;
  final int month;
  final double totalExpense;
  final double totalIncome;
  final List<CategoryStat> categoryStats;

  AnalysisRequest({
    required this.year,
    required this.month,
    required this.totalExpense,
    required this.totalIncome,
    required this.categoryStats,
  });

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      'month': month,
      'totalExpense': totalExpense,
      'totalIncome': totalIncome,
      'balance': totalIncome - totalExpense,
      'categoryStats': categoryStats.map((s) => s.toJson()).toList(),
    };
  }
}

/// 类别统计模型
/// 用于分析时的类别消费统计
class CategoryStat {
  final String categoryName;
  final double amount;
  final double percentage;
  final int type; // 0=支出, 1=收入

  CategoryStat({
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'categoryName': categoryName,
      'amount': amount,
      'percentage': percentage,
      'type': type,
    };
  }
}
