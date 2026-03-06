import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';

/// 日期范围选择器组件
/// 提供快捷选项和自定义日期范围选择
class DateRangeSelector extends ConsumerWidget {
  final DateTimeRange selectedRange;
  final ValueChanged<DateTimeRange> onRangeChanged;

  const DateRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MM/dd');
    final startText = dateFormat.format(selectedRange.start);
    final endText = dateFormat.format(selectedRange.end);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快捷选项
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickOption(
                  context: context,
                  label: '本周',
                  isSelected: _isThisWeek(selectedRange),
                  onTap: () => onRangeChanged(_getThisWeek()),
                ),
                const SizedBox(width: 8),
                _buildQuickOption(
                  context: context,
                  label: '本月',
                  isSelected: _isThisMonth(selectedRange),
                  onTap: () => onRangeChanged(_getThisMonth()),
                ),
                const SizedBox(width: 8),
                _buildQuickOption(
                  context: context,
                  label: '上月',
                  isSelected: _isLastMonth(selectedRange),
                  onTap: () => onRangeChanged(_getLastMonth()),
                ),
                const SizedBox(width: 8),
                _buildQuickOption(
                  context: context,
                  label: '本年',
                  isSelected: _isThisYear(selectedRange),
                  onTap: () => onRangeChanged(_getThisYear()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 自定义日期选择
          InkWell(
            onTap: () => _showDateRangePicker(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$startText - $endText',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建快捷选项按钮
  Widget _buildQuickOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.divider,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// 显示日期范围选择器
  Future<void> _showDateRangePicker(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: Theme.of(context).appBarTheme.copyWith(
              backgroundColor: AppColors.brandPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onRangeChanged(picked);
    }
  }

  /// 判断是否为本周
  bool _isThisWeek(DateTimeRange range) {
    final thisWeek = _getThisWeek();
    return _isSameDay(range.start, thisWeek.start) &&
        _isSameDay(range.end, thisWeek.end);
  }

  /// 判断是否为本月
  bool _isThisMonth(DateTimeRange range) {
    final thisMonth = _getThisMonth();
    return _isSameDay(range.start, thisMonth.start) &&
        _isSameDay(range.end, thisMonth.end);
  }

  /// 判断是否为上月
  bool _isLastMonth(DateTimeRange range) {
    final lastMonth = _getLastMonth();
    return _isSameDay(range.start, lastMonth.start) &&
        _isSameDay(range.end, lastMonth.end);
  }

  /// 判断是否为本年
  bool _isThisYear(DateTimeRange range) {
    final thisYear = _getThisYear();
    return _isSameDay(range.start, thisYear.start) &&
        _isSameDay(range.end, thisYear.end);
  }

  /// 判断是否为同一天
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 获取本周日期范围
  DateTimeRange _getThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return DateTimeRange(
      start: DateTime(weekStart.year, weekStart.month, weekStart.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// 获取本月日期范围
  DateTimeRange _getThisMonth() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  /// 获取上月日期范围
  DateTimeRange _getLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    final lastDay = DateTime(now.year, now.month, 0);
    return DateTimeRange(
      start: DateTime(lastMonth.year, lastMonth.month, 1),
      end: DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59),
    );
  }

  /// 获取本年日期范围
  DateTimeRange _getThisYear() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, 1, 1),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }
}

/// 获取本周开始时间
DateTime getWeekStart(DateTime date) {
  final weekday = date.weekday;
  final daysToSubtract = weekday - 1;
  final startOfDay = DateTime(date.year, date.month, date.day);
  return startOfDay.subtract(Duration(days: daysToSubtract));
}
