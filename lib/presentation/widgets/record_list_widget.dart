import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/models/record_model.dart';
import '../providers/categories_provider.dart';
import '../providers/records_provider.dart';
import 'edit_record_sheet.dart';
import 'top_notification.dart';

/// 记录列表组件
/// 显示记账记录列表，支持按日期分组、滑动删除和点击编辑
class RecordListWidget extends ConsumerWidget {
  const RecordListWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredRecordsAsync = ref.watch(filteredRecordsProvider);

    return filteredRecordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildRecordList(context, ref, records);
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('加载失败: $error'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(recordsProvider.notifier).loadRecords(),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态显示
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '该时间段暂无记录',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方导航栏的话筒或记账按钮开始记录',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// 构建记录列表
  Widget _buildRecordList(BuildContext context, WidgetRef ref, List<RecordModel> records) {
    // 按日期分组
    final groupedRecords = _groupRecordsByDate(records);
    final sortedDates = groupedRecords.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayRecords = groupedRecords[date]!;
        return _buildDayGroup(context, ref, date, dayRecords);
      },
    );
  }

  /// 按日期分组记录
  Map<DateTime, List<RecordModel>> _groupRecordsByDate(List<RecordModel> records) {
    final groups = <DateTime, List<RecordModel>>{};
    for (final record in records) {
      final date = DateTime(
        record.createdAt.year,
        record.createdAt.month,
        record.createdAt.day,
      );
      groups.putIfAbsent(date, () => []).add(record);
    }
    return groups;
  }

  /// 构建日期分组
  Widget _buildDayGroup(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    List<RecordModel> records,
  ) {
    final theme = Theme.of(context);
    final dateLabel = _getDateLabel(date);
    final dateFormat = DateFormat('MM月dd日');

    // 计算当天收支
    double dayExpense = 0;
    double dayIncome = 0;
    for (final record in records) {
      if (record.type == 0) {
        dayExpense += record.amount;
      } else {
        dayIncome += record.amount;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                dateLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (dayExpense > 0)
                Text(
                  '支出 ¥${dayExpense.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.expenseColor,
                  ),
                ),
              if (dayIncome > 0) ...[
                if (dayExpense > 0) const SizedBox(width: 12),
                Text(
                  '收入 ¥${dayIncome.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.incomeColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        // 记录列表
        ...records.map((record) => _buildRecordItem(context, ref, record)),
      ],
    );
  }

  /// 获取日期标签
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return '今天';
    } else if (dateOnly == yesterday) {
      return '昨天';
    } else {
      final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
      return weekdays[date.weekday - 1];
    }
  }

  /// 构建记录项
  Widget _buildRecordItem(BuildContext context, WidgetRef ref, RecordModel record) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        final category = categories.firstWhere(
          (c) => c.id == record.categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: '未知分类',
            icon: 'help',
            type: record.type,
            isPreset: false,
            isEnabled: true,
            sortOrder: 0,
          ),
        );

        return Dismissible(
          key: Key(record.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppColors.error,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) async {
            try {
              await ref.read(recordsProvider.notifier).deleteRecord(record.id);
              if (context.mounted) {
                TopNotification.success(context, '已删除');
              }
            } catch (e) {
              if (context.mounted) {
                TopNotification.error(context, '删除失败: $e');
              }
            }
          },
          child: InkWell(
            onTap: () => showEditRecordSheet(context, record),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(category.icon),
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 类别和备注
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              category.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('HH:mm').format(record.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        if (record.note != null && record.note!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            record.note!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 金额
                  Text(
                    '${record.type == 0 ? '-' : '+'}¥${record.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: record.type == 0 ? AppColors.expenseColor : AppColors.incomeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const ListTile(
        leading: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('加载中...'),
      ),
      error: (_, __) => ListTile(
        leading: Icon(Icons.error, color: AppColors.error),
        title: const Text('加载失败'),
      ),
    );
  }

  /// 获取图标数据
  IconData _getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'home': Icons.home,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'more_horiz': Icons.more_horiz,
      'work': Icons.work,
      'card_giftcard': Icons.card_giftcard,
      'trending_up': Icons.trending_up,
      'timer': Icons.timer,
      'redeem': Icons.redeem,
      'help': Icons.help_outline,
      'cleaning_services': Icons.cleaning_services,
      'checkroom': Icons.checkroom,
      'face': Icons.face,
      'fitness_center': Icons.fitness_center,
      'pets': Icons.pets,
      'group': Icons.group,
      'flight': Icons.flight,
      'devices': Icons.devices,
      'payments': Icons.payments,
      'replay': Icons.replay,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
