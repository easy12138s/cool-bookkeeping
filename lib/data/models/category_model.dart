import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_model.freezed.dart';
part 'category_model.g.dart';

/// 分类数据模型
/// 用于表示收入或支出的分类
@freezed
class CategoryModel with _$CategoryModel {
  const factory CategoryModel({
    /// 分类唯一标识符
    required String id,

    /// 分类名称
    required String name,

    /// 图标名称
    required String icon,

    /// 类型：0=支出, 1=收入
    required int type,

    /// 是否预设分类
    required bool isPreset,

    /// 是否启用
    required bool isEnabled,

    /// 排序顺序
    required int sortOrder,
  }) = _CategoryModel;

  /// 从 JSON 反序列化
  factory CategoryModel.fromJson(Map<String, Object?> json) =>
      _$CategoryModelFromJson(json);
}
