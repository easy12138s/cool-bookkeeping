import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/record_model.dart';
import '../../data/repositories/records_repository.dart';
import '../../data/repositories/web_records_repository.dart';
import 'providers.dart';

/// Records Notifier 状态类型
typedef RecordsState = AsyncValue<List<RecordModel>>;

/// Records Notifier
/// 管理记账记录列表的状态和业务逻辑
class RecordsNotifier extends StateNotifier<RecordsState> {
  final dynamic _repository;

  RecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRecords();
  }

  /// 加载所有记录
  /// 从 Repository 获取数据并更新状态
  Future<void> loadRecords() async {
    if (kDebugMode) {
      print('[RecordsNotifier] loadRecords started');
    }
    state = const AsyncValue.loading();
    try {
      final List<RecordModel> records;
      if (kIsWeb) {
        records = await (_repository as WebRecordsRepository).getAllRecords();
      } else {
        records = await (_repository as RecordsRepository).getAllRecords();
      }
      if (kDebugMode) {
        print('[RecordsNotifier] loadRecords completed, records count: ${records.length}');
        for (final r in records) {
          print('  - id: ${r.id}, type: ${r.type}, amount: ${r.amount}, categoryId: ${r.categoryId}');
        }
      }
      state = AsyncValue.data(records);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('[RecordsNotifier] loadRecords error: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 添加新记录
  /// [record] 要添加的记录模型
  Future<void> addRecord(RecordModel record) async {
    if (kDebugMode) {
      print('[RecordsNotifier] addRecord called: id=${record.id}, type=${record.type}, amount=${record.amount}');
    }
    try {
      if (kIsWeb) {
        await (_repository as WebRecordsRepository).insertRecord(record);
      } else {
        await (_repository as RecordsRepository).insertRecord(record);
      }
      await loadRecords();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('[RecordsNotifier] addRecord error: $error');
      }
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 更新记录
  /// [record] 要更新的记录模型
  Future<void> updateRecord(RecordModel record) async {
    try {
      if (kIsWeb) {
        await (_repository as WebRecordsRepository).updateRecord(record);
      } else {
        await (_repository as RecordsRepository).updateRecord(record);
      }
      await loadRecords();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 删除记录
  /// [id] 要删除的记录 ID
  Future<void> deleteRecord(String id) async {
    try {
      if (kIsWeb) {
        await (_repository as WebRecordsRepository).deleteRecord(id);
      } else {
        await (_repository as RecordsRepository).deleteRecord(id);
      }
      await loadRecords();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 根据类型和日期范围获取总金额
  Future<double> getTotalAmountByType(int type, DateTime start, DateTime end) async {
    try {
      if (kIsWeb) {
        return await (_repository as WebRecordsRepository).getTotalAmountByType(type, start, end);
      } else {
        return await (_repository as RecordsRepository).getTotalAmountByType(type, start, end);
      }
    } catch (error) {
      return 0.0;
    }
  }
}

/// Records Provider
/// 提供 RecordsNotifier 实例
final recordsProvider = StateNotifierProvider<RecordsNotifier, RecordsState>(
  (ref) {
    final repository = ref.watch(recordsRepositoryProvider);
    return RecordsNotifier(repository);
  },
);

/// 日期范围 Provider
/// 用于首页日期筛选，默认本周
final dateRangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  final weekStart = _getWeekStart(now);
  return DateTimeRange(
    start: weekStart,
    end: DateTime(now.year, now.month, now.day, 23, 59, 59),
  );
});

/// 筛选后的记录 Provider
/// 根据 dateRangeProvider 筛选记录
final filteredRecordsProvider = Provider<AsyncValue<List<RecordModel>>>((ref) {
  final recordsAsync = ref.watch(recordsProvider);
  final dateRange = ref.watch(dateRangeProvider);

  return recordsAsync.when(
    data: (records) {
      final filtered = records.where((record) {
        return record.createdAt.isAfter(
              dateRange.start.subtract(const Duration(seconds: 1)),
            ) &&
            record.createdAt.isBefore(
              dateRange.end.add(const Duration(seconds: 1)),
            );
      }).toList();

      // 按时间倒序排列（最新的在前）
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// 本周记录 Provider（兼容旧代码）
/// 自动监听 recordsProvider 变化并筛选本周记录
final weeklyRecordsProvider = Provider<AsyncValue<List<RecordModel>>>((ref) {
  final recordsAsync = ref.watch(recordsProvider);

  return recordsAsync.when(
    data: (records) {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekEnd = weekStart.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );

      final weeklyRecords = records.where((record) {
        return record.createdAt.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
               record.createdAt.isBefore(weekEnd.add(const Duration(seconds: 1)));
      }).toList();

      // 按时间倒序排列（最新的在前）
      weeklyRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return AsyncValue.data(weeklyRecords);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// 本周统计 Provider
/// 提供本周的支出、收入、结余统计
final weeklySummaryProvider = Provider<AsyncValue<WeeklySummary>>((ref) {
  final weeklyRecordsAsync = ref.watch(weeklyRecordsProvider);

  return weeklyRecordsAsync.when(
    data: (records) {
      final expense = records
          .where((r) => r.type == 0)
          .fold<double>(0.0, (sum, r) => sum + r.amount);
      final income = records
          .where((r) => r.type == 1)
          .fold<double>(0.0, (sum, r) => sum + r.amount);

      return AsyncValue.data(WeeklySummary(
        expense: expense,
        income: income,
        balance: income - expense,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// 获取本周开始时间（周一 00:00:00）
DateTime _getWeekStart(DateTime date) {
  final weekday = date.weekday;
  final daysToSubtract = weekday - 1;
  final startOfDay = DateTime(date.year, date.month, date.day);
  return startOfDay.subtract(Duration(days: daysToSubtract));
}

/// 本周统计数据类
class WeeklySummary {
  final double expense;
  final double income;
  final double balance;

  const WeeklySummary({
    required this.expense,
    required this.income,
    required this.balance,
  });
}
