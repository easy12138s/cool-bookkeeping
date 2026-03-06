import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/daos/records_dao.dart';
import '../models/record_model.dart';

/// 记录 Repository 层
/// 负责记录数据的业务逻辑处理和数据转换
class RecordsRepository {
  final RecordsDao _recordsDao;

  RecordsRepository(this._recordsDao);

  /// 获取所有记录
  Future<List<RecordModel>> getAllRecords() async {
    final records = await _recordsDao.getAllRecords();
    return records.map(_toModel).toList();
  }

  /// 根据日期范围获取记录
  Future<List<RecordModel>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final records = await _recordsDao.getRecordsByDateRange(start, end);
    return records.map(_toModel).toList();
  }

  /// 根据 ID 获取单条记录
  Future<RecordModel?> getRecordById(String id) async {
    final record = await _recordsDao.getRecordById(id);
    return record != null ? _toModel(record) : null;
  }

  /// 插入新记录
  Future<void> insertRecord(RecordModel model) async {
    final companion = _toCompanion(model);
    await _recordsDao.insertRecord(companion);
  }

  /// 更新记录
  Future<void> updateRecord(RecordModel model) async {
    final companion = _toCompanion(model);
    await _recordsDao.updateRecord(companion);
  }

  /// 删除记录
  Future<void> deleteRecord(String id) async {
    await _recordsDao.deleteRecord(id);
  }

  /// 根据类型和日期范围获取总金额
  /// type: 0=支出, 1=收入
  Future<double> getTotalAmountByType(
    int type,
    DateTime start,
    DateTime end,
  ) async {
    return await _recordsDao.getTotalAmountByTypeAndDateRange(type, start, end);
  }

  /// 将数据库 Record 转换为 RecordModel
  RecordModel _toModel(Record record) {
    return RecordModel(
      id: record.id,
      amount: record.amount,
      categoryId: record.categoryId,
      type: record.type,
      note: record.note,
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
    );
  }

  /// 将 RecordModel 转换为数据库 RecordsCompanion
  RecordsCompanion _toCompanion(RecordModel model) {
    return RecordsCompanion(
      id: Value(model.id),
      amount: Value(model.amount),
      categoryId: Value(model.categoryId),
      type: Value(model.type),
      note: Value(model.note),
      createdAt: Value(model.createdAt),
      updatedAt: Value(model.updatedAt),
    );
  }
}
