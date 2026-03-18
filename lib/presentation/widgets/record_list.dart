import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/models/parsed_result.dart';
import '../../data/models/record_model.dart';
import '../providers/categories_provider.dart';
import '../providers/records_provider.dart';
import '../providers/voice_bookkeeping_provider.dart';
import 'confirmation_card.dart';

/// 记录列表组件
/// 显示按日期分组的记账记录列表
class RecordList extends ConsumerWidget {
  const RecordList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return _buildEmptyState(context);
        }

        return categoriesAsync.when(
          data: (categories) => _buildRecordList(context, ref, records, categories),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载类别失败: $error')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('加载记录失败: $error')),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无记账记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '长按下方语音按钮开始记账',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  /// 构建记录列表
  Widget _buildRecordList(
    BuildContext context,
    WidgetRef ref,
    List<RecordModel> records,
    List<CategoryModel> categories,
  ) {
    // 按日期分组
    final groupedRecords = _groupRecordsByDate(records);
    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return RefreshIndicator(
      onRefresh: () => ref.read(recordsProvider.notifier).loadRecords(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final dayRecords = groupedRecords[date]!;

          return _buildDayGroup(context, ref, date, dayRecords, categories);
        },
      ),
    );
  }

  /// 按日期分组记录
  Map<DateTime, List<RecordModel>> _groupRecordsByDate(
    List<RecordModel> records,
  ) {
    final grouped = <DateTime, List<RecordModel>>{};

    for (final record in records) {
      final date = DateTime(
        record.createdAt.year,
        record.createdAt.month,
        record.createdAt.day,
      );

      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(record);
    }

    // 对每个日期内的记录按时间倒序排序
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return grouped;
  }

  /// 构建日期分组
  Widget _buildDayGroup(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
    List<RecordModel> records,
    List<CategoryModel> categories,
  ) {
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);

    String dateLabel;
    if (isToday) {
      dateLabel = '今天';
    } else if (isYesterday) {
      dateLabel = '昨天';
    } else {
      dateLabel = DateFormat('MM月dd日').format(date);
    }

    // 计算当日收支
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              bottom: BorderSide(color: AppColors.divider),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
              Row(
                children: [
                  if (dayExpense > 0)
                    Text(
                      '支: ¥${dayExpense.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.expenseColor,
                          ),
                    ),
                  if (dayIncome > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '收: ¥${dayIncome.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.incomeColor,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // 记录列表
        ...records.map((record) => _buildRecordItem(
              context,
              ref,
              record,
              categories,
            )),
      ],
    );
  }

  /// 构建记录项
  Widget _buildRecordItem(
    BuildContext context,
    WidgetRef ref,
    RecordModel record,
    List<CategoryModel> categories,
  ) {
    final theme = Theme.of(context);
    final category = categories.firstWhere(
      (c) => c.id == record.categoryId,
      orElse: () => CategoryModel(
        id: '',
        name: '未知',
        icon: 'help',
        type: record.type,
        isPreset: true,
        isEnabled: true,
        sortOrder: 0,
      ),
    );

    final isExpense = record.type == 0;
    final amountColor = isExpense ? AppColors.expenseColor : AppColors.incomeColor;
    final amountPrefix = isExpense ? '-' : '+';

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog(context);
      },
      onDismissed: (direction) {
        ref.read(recordsProvider.notifier).deleteRecord(record.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录已删除')),
        );
      },
      child: InkWell(
        onTap: () => _editRecord(context, ref, record, category),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              // 类别图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: amountColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconData(category.icon),
                  color: amountColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // 类别和备注
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (record.note != null && record.note!.isNotEmpty)
                      Text(
                        record.note!,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // 金额和时间
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix¥${record.amount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(record.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 显示删除确认对话框
  Future<bool?> _showDeleteConfirmDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 编辑记录
  void _editRecord(
    BuildContext context,
    WidgetRef ref,
    RecordModel record,
    CategoryModel category,
  ) {
    // 设置解析结果用于编辑（单条记录用列表包装）
    ref.read(parsedResultsProvider.notifier).state = [
      ParsedResult(
        amount: record.amount,
        category: category.name,
        type: record.type == 0 ? '支出' : '收入',
        time: record.createdAt,
        note: record.note,
      )
    ];

    showConfirmationCard(context, ref);
  }

  /// 判断是否为今天
  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// 判断是否为昨天
  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
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
      'help': Icons.help,
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
