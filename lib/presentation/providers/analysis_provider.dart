import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/analysis_result.dart';
import '../../data/models/category_model.dart';
import '../../data/models/record_model.dart';
import '../../services/analysis_service.dart';
import 'categories_provider.dart';
import 'providers.dart';
import 'records_provider.dart';

/// 分析月份 Provider
/// 默认显示上月
final analysisMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month - 1);
});

/// 分析结果缓存 Provider
/// 键格式: yyyy-MM
final analysisCacheProvider = StateProvider<Map<String, AnalysisResult>>((ref) => {});

/// 分析加载状态 Provider
final analysisLoadingProvider = StateProvider<bool>((ref) => false);

/// 分析错误信息 Provider
final analysisErrorProvider = StateProvider<String?>((ref) => null);

/// 分析服务 Provider
final analysisServiceProvider = Provider<AnalysisService>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return AnalysisService(preferences: preferences);
});

/// 获取指定月份的记录
List<RecordModel> _getMonthRecords(List<RecordModel> records, DateTime month) {
  return records.where((r) {
    return r.createdAt.year == month.year && r.createdAt.month == month.month;
  }).toList();
}

/// 分析结果 Notifier
/// 管理分析结果的获取和缓存
class AnalysisNotifier extends StateNotifier<AsyncValue<AnalysisResult?>> {
  final Ref _ref;

  AnalysisNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 加载分析结果
  /// 优先从缓存获取，如果没有则返回 null（不自动触发分析）
  Future<void> loadAnalysis() async {
    final month = _ref.read(analysisMonthProvider);
    final cache = _ref.read(analysisCacheProvider);
    final cacheKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    // 检查缓存
    if (cache.containsKey(cacheKey)) {
      state = AsyncValue.data(cache[cacheKey]);
      return;
    }

    // 没有缓存，返回 null
    state = const AsyncValue.data(null);
  }

  /// 触发 AI 分析
  /// 调用 LLM 进行分析并缓存结果
  Future<void> analyze() async {
    final month = _ref.read(analysisMonthProvider);
    final cache = _ref.read(analysisCacheProvider);
    final cacheKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    _ref.read(analysisLoadingProvider.notifier).state = true;
    _ref.read(analysisErrorProvider.notifier).state = null;
    state = const AsyncValue.loading();

    try {
      // 获取记录和类别
      final recordsAsync = _ref.read(recordsProvider);
      final categoriesAsync = _ref.read(categoriesProvider);

      // 等待数据加载完成
      final records = recordsAsync.when(
        data: (d) => d,
        loading: () => <RecordModel>[],
        error: (_, __) => <RecordModel>[],
      );
      final categories = categoriesAsync.when(
        data: (d) => d,
        loading: () => <CategoryModel>[],
        error: (_, __) => <CategoryModel>[],
      );

      // 筛选该月记录
      final monthRecords = _getMonthRecords(records, month);

      if (monthRecords.isEmpty) {
        state = const AsyncValue.data(null);
        _ref.read(analysisErrorProvider.notifier).state = '该月份暂无记账记录';
        return;
      }

      // 调用分析服务
      final analysisService = _ref.read(analysisServiceProvider);
      final result = await analysisService.analyzeMonthlySpending(
        records: monthRecords,
        categories: categories,
        year: month.year,
        month: month.month,
      );

      // 更新缓存
      _ref.read(analysisCacheProvider.notifier).state = {
        ...cache,
        cacheKey: result,
      };

      state = AsyncValue.data(result);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      _ref.read(analysisErrorProvider.notifier).state = e.toString();
    } finally {
      _ref.read(analysisLoadingProvider.notifier).state = false;
    }
  }

  /// 清除当前月份缓存并重新分析
  Future<void> refreshAnalysis() async {
    final month = _ref.read(analysisMonthProvider);
    final cache = _ref.read(analysisCacheProvider);
    final cacheKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    // 清除缓存
    final newCache = Map<String, AnalysisResult>.from(cache);
    newCache.remove(cacheKey);
    _ref.read(analysisCacheProvider.notifier).state = newCache;

    // 重新分析
    await analyze();
  }

  /// 切换月份时自动加载
  void onMonthChanged(DateTime newMonth) {
    _ref.read(analysisMonthProvider.notifier).state = newMonth;
    loadAnalysis();
  }
}

/// 分析结果 Provider
final analysisResultProvider = StateNotifierProvider<AnalysisNotifier, AsyncValue<AnalysisResult?>>((ref) {
  return AnalysisNotifier(ref);
});

/// 当前月份是否有分析结果
final hasAnalysisResultProvider = Provider<bool>((ref) {
  final month = ref.watch(analysisMonthProvider);
  final cache = ref.watch(analysisCacheProvider);
  final cacheKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
  return cache.containsKey(cacheKey);
});

/// 当前月份的记录数量
final monthRecordCountProvider = Provider<int>((ref) {
  final month = ref.watch(analysisMonthProvider);
  final recordsAsync = ref.watch(recordsProvider);

  return recordsAsync.when(
    data: (records) => _getMonthRecords(records, month).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// 当前月份的收支统计
final monthSummaryProvider = Provider<Map<String, double>>((ref) {
  final month = ref.watch(analysisMonthProvider);
  final recordsAsync = ref.watch(recordsProvider);

  return recordsAsync.when(
    data: (records) {
      final monthRecords = _getMonthRecords(records, month);
      final expense = monthRecords
          .where((r) => r.type == 0)
          .fold<double>(0, (sum, r) => sum + r.amount);
      final income = monthRecords
          .where((r) => r.type == 1)
          .fold<double>(0, (sum, r) => sum + r.amount);
      return {
        'expense': expense,
        'income': income,
        'balance': income - expense,
      };
    },
    loading: () => {'expense': 0, 'income': 0, 'balance': 0},
    error: (_, __) => {'expense': 0, 'income': 0, 'balance': 0},
  );
});
