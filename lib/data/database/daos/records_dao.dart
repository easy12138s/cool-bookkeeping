import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/records_table.dart';

part 'records_dao.g.dart';

@DriftAccessor(tables: [Records])
class RecordsDao extends DatabaseAccessor<AppDatabase> with _$RecordsDaoMixin {
  RecordsDao(super.db);

  /// 获取所有记录，按创建时间倒序排列
  Future<List<Record>> getAllRecords() {
    return (select(records)
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
  }

  /// 获取所有记录（Stream 形式）
  Stream<List<Record>> watchAllRecords() {
    return (select(records)
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .watch();
  }

  /// 根据日期范围获取记录
  Future<List<Record>> getRecordsByDateRange(DateTime start, DateTime end) {
    return (select(records)
          ..where((r) => r.createdAt.isBetweenValues(start, end))
          ..orderBy([(r) => OrderingTerm.desc(r.createdAt)]))
        .get();
  }

  /// 根据 ID 获取单条记录
  Future<Record?> getRecordById(String id) {
    return (select(records)..where((r) => r.id.equals(id))).getSingleOrNull();
  }

  /// 插入记录
  Future<int> insertRecord(RecordsCompanion record) {
    return into(records).insert(record);
  }

  /// 更新记录
  Future<bool> updateRecord(RecordsCompanion record) {
    return update(records).replace(record);
  }

  /// 删除记录
  Future<int> deleteRecord(String id) {
    return (delete(records)..where((r) => r.id.equals(id))).go();
  }

  /// 根据类型获取总金额
  /// type: 0=支出, 1=收入
  Future<double> getTotalAmountByType(int type) async {
    final query = select(records)
      ..where((r) => r.type.equals(type));

    final recordsList = await query.get();
    return recordsList.fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// 根据日期范围和类型获取总金额
  Future<double> getTotalAmountByTypeAndDateRange(
    int type,
    DateTime start,
    DateTime end,
  ) async {
    final query = select(records)
      ..where(
        (r) => r.type.equals(type) & r.createdAt.isBetweenValues(start, end),
      );

    final recordsList = await query.get();
    return recordsList.fold<double>(0.0, (sum, r) => sum + r.amount);
  }
}
