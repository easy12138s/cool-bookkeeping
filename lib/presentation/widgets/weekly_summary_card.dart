import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../providers/records_provider.dart';

/// 本周统计卡片组件
/// 显示本周的支出、收入和结余统计
class WeeklySummaryCard extends ConsumerWidget {
  const WeeklySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklySummaryProvider);

    return summaryAsync.when(
      data: (summary) => _buildCard(context, summary),
      loading: () => _buildLoadingCard(context),
      error: (error, _) => _buildErrorCard(context, error.toString()),
    );
  }

  /// 构建统计卡片
  Widget _buildCard(BuildContext context, WeeklySummary summary) {
    // 响应式边距和内边距
    final cardMargin = ResponsiveSpacing.getResponsiveSpacing(
      context,
      baseSpacing: 16.0,
    );

    final cardPadding = ResponsiveSpacing.getResponsiveSpacing(
      context,
      baseSpacing: 20.0,
    );

    return Container(
      margin: EdgeInsets.all(cardMargin),
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandPrimary,
            AppColors.brandSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '本周收支',
                style: AppTextStyles.getHeadlineMedium(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: AppSpacing.symmetric(
                  context: context,
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getWeekRangeText(),
                  style: AppTextStyles.getBodyMedium(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.height(context, 20),

          // 结余显示
          Text(
            '结余',
            style: AppTextStyles.getBodyMedium(context).copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          AppSpacing.height(context, 4),
          // 使用更小的字体显示结余金额，防止溢出
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '¥${summary.balance.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22, // 固定小字体，配合 FittedBox 自动缩放
              ),
            ),
          ),
          AppSpacing.height(context, 20),

          // 收支明细
          Row(
            children: [
              // 收入
              Expanded(
                child: _buildAmountItem(
                  context: context,
                  label: '收入',
                  amount: summary.income,
                  icon: Icons.arrow_downward,
                  iconColor: Colors.green.shade300,
                ),
              ),
              // 分隔线
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              // 支出
              Expanded(
                child: _buildAmountItem(
                  context: context,
                  label: '支出',
                  amount: summary.expense,
                  icon: Icons.arrow_upward,
                  iconColor: Colors.red.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建金额项
  Widget _buildAmountItem({
    required BuildContext context,
    required String label,
    required double amount,
    required IconData icon,
    required Color iconColor,
  }) {
    // 响应式尺寸
    final iconSize = ResponsiveSpacing.getResponsiveSpacing(
      context,
      baseSpacing: 32.0,
    );

    final iconInnerSize = ResponsiveSpacing.getResponsiveSpacing(
      context,
      baseSpacing: 16.0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: iconInnerSize,
            color: iconColor,
          ),
        ),
        AppSpacing.width(context, 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.getBodyMedium(context).copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            AppSpacing.height(context, 2),
            // 使用更小的字体显示收入/支出金额，防止溢出
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '¥${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16, // 固定小字体，配合 FittedBox 自动缩放
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建加载状态卡片
  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 构建错误状态卡片
  Widget _buildErrorCard(BuildContext context, String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 32),
            AppSpacing.height(context, 8),
            Text(
              '加载失败',
              style: AppTextStyles.getTitleMedium(context).copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取本周日期范围文本
  String _getWeekRangeText() {
    final now = DateTime.now();
    final weekStart = _getWeekStart(now);
    final weekEnd = weekStart.add(const Duration(days: 6));

    final startMonth = weekStart.month.toString().padLeft(2, '0');
    final startDay = weekStart.day.toString().padLeft(2, '0');
    final endMonth = weekEnd.month.toString().padLeft(2, '0');
    final endDay = weekEnd.day.toString().padLeft(2, '0');

    return '$startMonth/$startDay-$endMonth/$endDay';
  }

  /// 获取本周开始时间
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    final daysToSubtract = weekday - 1;
    final startOfDay = DateTime(date.year, date.month, date.day);
    return startOfDay.subtract(Duration(days: daysToSubtract));
  }
}
