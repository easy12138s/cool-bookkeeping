import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/record_model.dart';

/// Web 平台记录 Repository
/// 使用 shared_preferences 存储 JSON 格式的记录数据
class WebRecordsRepository {
  final SharedPreferences _prefs;
  static const String _recordsKey = 'web_records';

  WebRecordsRepository(this._prefs);

  /// 获取所有记录
  Future<List<RecordModel>> getAllRecords() async {
    final jsonString = _prefs.getString(_recordsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => RecordModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 根据日期范围获取记录
  Future<List<RecordModel>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final records = await getAllRecords();
    return records.where((r) {
      return r.createdAt.isAfter(start) && r.createdAt.isBefore(end);
    }).toList();
  }

  /// 根据 ID 获取单条记录
  Future<RecordModel?> getRecordById(String id) async {
    final records = await getAllRecords();
    try {
      return records.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 插入新记录
  Future<void> insertRecord(RecordModel model) async {
    final records = await getAllRecords();
    records.add(model);
    await _saveRecords(records);
  }

  /// 批量插入记录
  Future<void> insertRecords(List<RecordModel> models) async {
    final records = await getAllRecords();
    records.addAll(models);
    await _saveRecords(records);
  }

  /// 更新记录
  Future<void> updateRecord(RecordModel model) async {
    final records = await getAllRecords();
    final index = records.indexWhere((r) => r.id == model.id);
    if (index != -1) {
      records[index] = model;
      await _saveRecords(records);
    }
  }

  /// 删除记录
  Future<void> deleteRecord(String id) async {
    final records = await getAllRecords();
    records.removeWhere((r) => r.id == id);
    await _saveRecords(records);
  }

  /// 根据类型和日期范围获取总金额
  Future<double> getTotalAmountByType(
    int type,
    DateTime start,
    DateTime end,
  ) async {
    final records = await getRecordsByDateRange(start, end);
    return records
        .where((r) => r.type == type)
        .fold<double>(0.0, (sum, r) => sum + r.amount);
  }

  /// 获取本周记录
  /// 本周定义为：周一 00:00:00 到周日 23:59:59
  Future<List<RecordModel>> getRecordsByWeek(DateTime date) async {
    final weekStart = _getWeekStart(date);
    final weekEnd = weekStart.add(
      const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
    );
    return getRecordsByDateRange(weekStart, weekEnd);
  }

  /// 获取本周开始时间（周一 00:00:00）
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1=Monday, 7=Sunday
    final daysToSubtract = weekday - 1;
    final startOfDay = DateTime(date.year, date.month, date.day);
    return startOfDay.subtract(Duration(days: daysToSubtract));
  }

  /// 保存记录列表到 SharedPreferences
  Future<void> _saveRecords(List<RecordModel> records) async {
    final jsonList = records.map((r) => r.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_recordsKey, jsonString);
  }

  /// 清除所有记录（用于测试）
  Future<void> clearAllRecords() async {
    await _prefs.remove(_recordsKey);
  }
}
