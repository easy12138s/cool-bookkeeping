// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) {
  return _AnalysisResult.fromJson(json);
}

/// @nodoc
mixin _$AnalysisResult {
  /// 总体评价（1-2句话总结）
  String get summary => throw _privateConstructorUsedError;

  /// 消费概况分析
  String get overview => throw _privateConstructorUsedError;

  /// 类别消费分析
  String get categoryAnalysis => throw _privateConstructorUsedError;

  /// 智能建议列表
  List<String> get suggestions => throw _privateConstructorUsedError;

  /// 趋势洞察
  String get trends => throw _privateConstructorUsedError;

  /// 下月消费预测
  String get prediction => throw _privateConstructorUsedError;

  /// 消费健康评分（0-100）
  int get score => throw _privateConstructorUsedError;

  /// 分析时间戳
  DateTime get analyzedAt => throw _privateConstructorUsedError;

  /// Serializes this AnalysisResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalysisResultCopyWith<AnalysisResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalysisResultCopyWith<$Res> {
  factory $AnalysisResultCopyWith(
    AnalysisResult value,
    $Res Function(AnalysisResult) then,
  ) = _$AnalysisResultCopyWithImpl<$Res, AnalysisResult>;
  @useResult
  $Res call({
    String summary,
    String overview,
    String categoryAnalysis,
    List<String> suggestions,
    String trends,
    String prediction,
    int score,
    DateTime analyzedAt,
  });
}

/// @nodoc
class _$AnalysisResultCopyWithImpl<$Res, $Val extends AnalysisResult>
    implements $AnalysisResultCopyWith<$Res> {
  _$AnalysisResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summary = null,
    Object? overview = null,
    Object? categoryAnalysis = null,
    Object? suggestions = null,
    Object? trends = null,
    Object? prediction = null,
    Object? score = null,
    Object? analyzedAt = null,
  }) {
    return _then(
      _value.copyWith(
            summary: null == summary
                ? _value.summary
                : summary // ignore: cast_nullable_to_non_nullable
                      as String,
            overview: null == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryAnalysis: null == categoryAnalysis
                ? _value.categoryAnalysis
                : categoryAnalysis // ignore: cast_nullable_to_non_nullable
                      as String,
            suggestions: null == suggestions
                ? _value.suggestions
                : suggestions // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            trends: null == trends
                ? _value.trends
                : trends // ignore: cast_nullable_to_non_nullable
                      as String,
            prediction: null == prediction
                ? _value.prediction
                : prediction // ignore: cast_nullable_to_non_nullable
                      as String,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
            analyzedAt: null == analyzedAt
                ? _value.analyzedAt
                : analyzedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnalysisResultImplCopyWith<$Res>
    implements $AnalysisResultCopyWith<$Res> {
  factory _$$AnalysisResultImplCopyWith(
    _$AnalysisResultImpl value,
    $Res Function(_$AnalysisResultImpl) then,
  ) = __$$AnalysisResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String summary,
    String overview,
    String categoryAnalysis,
    List<String> suggestions,
    String trends,
    String prediction,
    int score,
    DateTime analyzedAt,
  });
}

/// @nodoc
class __$$AnalysisResultImplCopyWithImpl<$Res>
    extends _$AnalysisResultCopyWithImpl<$Res, _$AnalysisResultImpl>
    implements _$$AnalysisResultImplCopyWith<$Res> {
  __$$AnalysisResultImplCopyWithImpl(
    _$AnalysisResultImpl _value,
    $Res Function(_$AnalysisResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? summary = null,
    Object? overview = null,
    Object? categoryAnalysis = null,
    Object? suggestions = null,
    Object? trends = null,
    Object? prediction = null,
    Object? score = null,
    Object? analyzedAt = null,
  }) {
    return _then(
      _$AnalysisResultImpl(
        summary: null == summary
            ? _value.summary
            : summary // ignore: cast_nullable_to_non_nullable
                  as String,
        overview: null == overview
            ? _value.overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryAnalysis: null == categoryAnalysis
            ? _value.categoryAnalysis
            : categoryAnalysis // ignore: cast_nullable_to_non_nullable
                  as String,
        suggestions: null == suggestions
            ? _value._suggestions
            : suggestions // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        trends: null == trends
            ? _value.trends
            : trends // ignore: cast_nullable_to_non_nullable
                  as String,
        prediction: null == prediction
            ? _value.prediction
            : prediction // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
        analyzedAt: null == analyzedAt
            ? _value.analyzedAt
            : analyzedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalysisResultImpl implements _AnalysisResult {
  const _$AnalysisResultImpl({
    required this.summary,
    required this.overview,
    required this.categoryAnalysis,
    required final List<String> suggestions,
    required this.trends,
    required this.prediction,
    required this.score,
    required this.analyzedAt,
  }) : _suggestions = suggestions;

  factory _$AnalysisResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalysisResultImplFromJson(json);

  /// 总体评价（1-2句话总结）
  @override
  final String summary;

  /// 消费概况分析
  @override
  final String overview;

  /// 类别消费分析
  @override
  final String categoryAnalysis;

  /// 智能建议列表
  final List<String> _suggestions;

  /// 智能建议列表
  @override
  List<String> get suggestions {
    if (_suggestions is EqualUnmodifiableListView) return _suggestions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_suggestions);
  }

  /// 趋势洞察
  @override
  final String trends;

  /// 下月消费预测
  @override
  final String prediction;

  /// 消费健康评分（0-100）
  @override
  final int score;

  /// 分析时间戳
  @override
  final DateTime analyzedAt;

  @override
  String toString() {
    return 'AnalysisResult(summary: $summary, overview: $overview, categoryAnalysis: $categoryAnalysis, suggestions: $suggestions, trends: $trends, prediction: $prediction, score: $score, analyzedAt: $analyzedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalysisResultImpl &&
            (identical(other.summary, summary) || other.summary == summary) &&
            (identical(other.overview, overview) ||
                other.overview == overview) &&
            (identical(other.categoryAnalysis, categoryAnalysis) ||
                other.categoryAnalysis == categoryAnalysis) &&
            const DeepCollectionEquality().equals(
              other._suggestions,
              _suggestions,
            ) &&
            (identical(other.trends, trends) || other.trends == trends) &&
            (identical(other.prediction, prediction) ||
                other.prediction == prediction) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.analyzedAt, analyzedAt) ||
                other.analyzedAt == analyzedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    summary,
    overview,
    categoryAnalysis,
    const DeepCollectionEquality().hash(_suggestions),
    trends,
    prediction,
    score,
    analyzedAt,
  );

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalysisResultImplCopyWith<_$AnalysisResultImpl> get copyWith =>
      __$$AnalysisResultImplCopyWithImpl<_$AnalysisResultImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalysisResultImplToJson(this);
  }
}

abstract class _AnalysisResult implements AnalysisResult {
  const factory _AnalysisResult({
    required final String summary,
    required final String overview,
    required final String categoryAnalysis,
    required final List<String> suggestions,
    required final String trends,
    required final String prediction,
    required final int score,
    required final DateTime analyzedAt,
  }) = _$AnalysisResultImpl;

  factory _AnalysisResult.fromJson(Map<String, dynamic> json) =
      _$AnalysisResultImpl.fromJson;

  /// 总体评价（1-2句话总结）
  @override
  String get summary;

  /// 消费概况分析
  @override
  String get overview;

  /// 类别消费分析
  @override
  String get categoryAnalysis;

  /// 智能建议列表
  @override
  List<String> get suggestions;

  /// 趋势洞察
  @override
  String get trends;

  /// 下月消费预测
  @override
  String get prediction;

  /// 消费健康评分（0-100）
  @override
  int get score;

  /// 分析时间戳
  @override
  DateTime get analyzedAt;

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalysisResultImplCopyWith<_$AnalysisResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
