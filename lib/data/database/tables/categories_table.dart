import 'package:drift/drift.dart';

@DataClassName('Category')
class Categories extends Table {
  /// 主键，使用 UUID
  TextColumn get id => text()();

  /// 分类名称
  TextColumn get name => text()();

  /// 图标名称
  TextColumn get icon => text()();

  /// 类型：0=支出, 1=收入
  IntColumn get type => integer()();

  /// 是否预设分类
  BoolColumn get isPreset => boolean()();

  /// 是否启用
  BoolColumn get isEnabled => boolean()();

  /// 排序顺序
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
