import 'package:drift/drift.dart';

@DataClassName('Record')
class Records extends Table {
  /// 主键，使用 UUID
  TextColumn get id => text()();

  /// 金额
  RealColumn get amount => real()();

  /// 分类 ID
  TextColumn get categoryId => text()();

  /// 类型：0=支出, 1=收入
  IntColumn get type => integer()();

  /// 备注（可选）
  TextColumn get note => text().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 更新时间（可选）
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
