import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';

/// 月份选择器组件
/// 用于智能分析页面选择分析的月份
class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && 
                          selectedMonth.month == now.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一个月按钮
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left),
            color: AppColors.textPrimary,
          ),
          
          // 月份显示
          GestureDetector(
            onTap: () => _showMonthPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('yyyy年MM月').format(selectedMonth),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.brandPrimary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // 下一个月按钮
          IconButton(
            onPressed: isCurrentMonth ? null : () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right),
            color: isCurrentMonth ? AppColors.divider : AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  /// 切换月份
  void _changeMonth(int delta) {
    final newMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + delta,
    );
    onMonthChanged(newMonth);
  }

  /// 显示月份选择器
  Future<void> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择月份'),
        content: SizedBox(
          width: double.maxFinite,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: now,
            selectedDate: selectedMonth,
            onChanged: (date) {
              Navigator.pop(context);
              _showMonthGrid(context, date.year);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  /// 显示月份网格
  void _showMonthGrid(BuildContext context, int year) {
    final now = DateTime.now();
    final isCurrentYear = year == now.year;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$year年'),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            childAspectRatio: 1.5,
            children: List.generate(12, (index) {
              final month = index + 1;
              final isFuture = isCurrentYear && month > now.month;
              final isSelected = year == selectedMonth.year && 
                               month == selectedMonth.month;

              return InkWell(
                onTap: isFuture ? null : () {
                  Navigator.pop(context);
                  onMonthChanged(DateTime(year, month));
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.brandPrimary 
                        : isFuture 
                            ? Colors.grey.shade200 
                            : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$month月',
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : isFuture 
                              ? Colors.grey 
                              : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
