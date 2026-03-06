// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parsed_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ParsedResult _$ParsedResultFromJson(Map<String, dynamic> json) {
  return _ParsedResult.fromJson(json);
}

/// @nodoc
mixin _$ParsedResult {
  /// 金额
  double? get amount => throw _privateConstructorUsedError;

  /// 类别名称，默认"其他"
  String get category => throw _privateConstructorUsedError;

  /// 类型，默认"支出"
  String get type => throw _privateConstructorUsedError;

  /// 时间
  DateTime? get time => throw _privateConstructorUsedError;

  /// 备注
  String? get note => throw _privateConstructorUsedError;

  /// 原始输入文本
  String? get rawText => throw _privateConstructorUsedError;

  /// Serializes this ParsedResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ParsedResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ParsedResultCopyWith<ParsedResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ParsedResultCopyWith<$Res> {
  factory $ParsedResultCopyWith(
    ParsedResult value,
    $Res Function(ParsedResult) then,
  ) = _$ParsedResultCopyWithImpl<$Res, ParsedResult>;
  @useResult
  $Res call({
    double? amount,
    String category,
    String type,
    DateTime? time,
    String? note,
    String? rawText,
  });
}

/// @nodoc
class _$ParsedResultCopyWithImpl<$Res, $Val extends ParsedResult>
    implements $ParsedResultCopyWith<$Res> {
  _$ParsedResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ParsedResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amount = freezed,
    Object? category = null,
    Object? type = null,
    Object? time = freezed,
    Object? note = freezed,
    Object? rawText = freezed,
  }) {
    return _then(
      _value.copyWith(
            amount: freezed == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double?,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            time: freezed == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
            rawText: freezed == rawText
                ? _value.rawText
                : rawText // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ParsedResultImplCopyWith<$Res>
    implements $ParsedResultCopyWith<$Res> {
  factory _$$ParsedResultImplCopyWith(
    _$ParsedResultImpl value,
    $Res Function(_$ParsedResultImpl) then,
  ) = __$$ParsedResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double? amount,
    String category,
    String type,
    DateTime? time,
    String? note,
    String? rawText,
  });
}

/// @nodoc
class __$$ParsedResultImplCopyWithImpl<$Res>
    extends _$ParsedResultCopyWithImpl<$Res, _$ParsedResultImpl>
    implements _$$ParsedResultImplCopyWith<$Res> {
  __$$ParsedResultImplCopyWithImpl(
    _$ParsedResultImpl _value,
    $Res Function(_$ParsedResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ParsedResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? amount = freezed,
    Object? category = null,
    Object? type = null,
    Object? time = freezed,
    Object? note = freezed,
    Object? rawText = freezed,
  }) {
    return _then(
      _$ParsedResultImpl(
        amount: freezed == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double?,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        time: freezed == time
            ? _value.time
            : time // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        rawText: freezed == rawText
            ? _value.rawText
            : rawText // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ParsedResultImpl implements _ParsedResult {
  const _$ParsedResultImpl({
    this.amount,
    this.category = '其他',
    this.type = '支出',
    this.time,
    this.note,
    this.rawText,
  });

  factory _$ParsedResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ParsedResultImplFromJson(json);

  /// 金额
  @override
  final double? amount;

  /// 类别名称，默认"其他"
  @override
  @JsonKey()
  final String category;

  /// 类型，默认"支出"
  @override
  @JsonKey()
  final String type;

  /// 时间
  @override
  final DateTime? time;

  /// 备注
  @override
  final String? note;

  /// 原始输入文本
  @override
  final String? rawText;

  @override
  String toString() {
    return 'ParsedResult(amount: $amount, category: $category, type: $type, time: $time, note: $note, rawText: $rawText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ParsedResultImpl &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.rawText, rawText) || other.rawText == rawText));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, amount, category, type, time, note, rawText);

  /// Create a copy of ParsedResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ParsedResultImplCopyWith<_$ParsedResultImpl> get copyWith =>
      __$$ParsedResultImplCopyWithImpl<_$ParsedResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ParsedResultImplToJson(this);
  }
}

abstract class _ParsedResult implements ParsedResult {
  const factory _ParsedResult({
    final double? amount,
    final String category,
    final String type,
    final DateTime? time,
    final String? note,
    final String? rawText,
  }) = _$ParsedResultImpl;

  factory _ParsedResult.fromJson(Map<String, dynamic> json) =
      _$ParsedResultImpl.fromJson;

  /// 金额
  @override
  double? get amount;

  /// 类别名称，默认"其他"
  @override
  String get category;

  /// 类型，默认"支出"
  @override
  String get type;

  /// 时间
  @override
  DateTime? get time;

  /// 备注
  @override
  String? get note;

  /// 原始输入文本
  @override
  String? get rawText;

  /// Create a copy of ParsedResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ParsedResultImplCopyWith<_$ParsedResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
