// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parsed_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ParsedResultImpl _$$ParsedResultImplFromJson(Map<String, dynamic> json) =>
    _$ParsedResultImpl(
      amount: (json['amount'] as num?)?.toDouble(),
      category: json['category'] as String? ?? '其他',
      type: json['type'] as String? ?? '支出',
      time: json['time'] == null
          ? null
          : DateTime.parse(json['time'] as String),
      note: json['note'] as String?,
      rawText: json['rawText'] as String?,
    );

Map<String, dynamic> _$$ParsedResultImplToJson(_$ParsedResultImpl instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'category': instance.category,
      'type': instance.type,
      'time': instance.time?.toIso8601String(),
      'note': instance.note,
      'rawText': instance.rawText,
    };
