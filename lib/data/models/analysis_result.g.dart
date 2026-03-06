// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnalysisResultImpl _$$AnalysisResultImplFromJson(Map<String, dynamic> json) =>
    _$AnalysisResultImpl(
      summary: json['summary'] as String,
      overview: json['overview'] as String,
      categoryAnalysis: json['categoryAnalysis'] as String,
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      trends: json['trends'] as String,
      prediction: json['prediction'] as String,
      score: (json['score'] as num).toInt(),
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
    );

Map<String, dynamic> _$$AnalysisResultImplToJson(
  _$AnalysisResultImpl instance,
) => <String, dynamic>{
  'summary': instance.summary,
  'overview': instance.overview,
  'categoryAnalysis': instance.categoryAnalysis,
  'suggestions': instance.suggestions,
  'trends': instance.trends,
  'prediction': instance.prediction,
  'score': instance.score,
  'analyzedAt': instance.analyzedAt.toIso8601String(),
};
