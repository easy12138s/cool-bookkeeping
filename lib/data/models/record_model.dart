import 'package:freezed_annotation/freezed_annotation.dart';

part 'record_model.freezed.dart';
part 'record_model.g.dart';

/// 记账记录数据模型
/// 用于表示一笔收入或支出记录
@freezed
class RecordModel with _$RecordModel {
  const factory RecordModel({
    /// 记录唯一标识符
    required String id,

    /// 金额
    required double amount,

    /// 分类 ID
    required String categoryId,

    /// 类型：0=支出, 1=收入
    required int type,

    /// 备注（可选）
    String? note,

    /// 创建时间
    required DateTime createdAt,

    /// 更新时间（可选）
    DateTime? updatedAt,
  }) = _RecordModel;

  /// 从 JSON 反序列化
  factory RecordModel.fromJson(Map<String, Object?> json) =>
      _$RecordModelFromJson(json);
}
