import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/analysis_result.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/top_notification.dart';

/// 智能分析页面
/// 显示月度消费分析报告
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化时加载分析结果
    Future.microtask(() {
      ref.read(analysisResultProvider.notifier).loadAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(analysisMonthProvider);
    final analysisAsync = ref.watch(analysisResultProvider);
    final isLoading = ref.watch(analysisLoadingProvider);
    final hasResult = ref.watch(hasAnalysisResultProvider);
    final recordCount = ref.watch(monthRecordCountProvider);
    final monthSummary = ref.watch(monthSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能分析'),
        centerTitle: true,
        actions: [
          // 刷新按钮
          if (hasResult)
            IconButton(
              onPressed: isLoading
                  ? null
                  : () => _refreshAnalysis(),
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: '重新分析',
            ),
        ],
      ),
      body: Column(
        children: [
          // 月份选择器
          MonthSelector(
            selectedMonth: selectedMonth,
            onMonthChanged: (month) {
              ref.read(analysisResultProvider.notifier).onMonthChanged(month);
            },
          ),

          // 月度收支概览
          _buildMonthSummary(monthSummary),

          // 分析内容
          Expanded(
            child: _buildAnalysisContent(
              analysisAsync: analysisAsync,
              isLoading: isLoading,
              hasResult: hasResult,
              recordCount: recordCount,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建月度收支概览
  Widget _buildMonthSummary(Map<String, double> summary) {
    final expense = summary['expense'] ?? 0;
    final income = summary['income'] ?? 0;
    final balance = summary['balance'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandPrimary, AppColors.brandSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              label: '支出',
              amount: expense,
              icon: Icons.arrow_upward,
              iconColor: Colors.red.shade300,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              label: '收入',
              amount: income,
              icon: Icons.arrow_downward,
              iconColor: Colors.green.shade300,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              label: '结余',
              amount: balance,
              icon: Icons.account_balance_wallet,
              iconColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required double amount,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '¥${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 构建分析内容
  Widget _buildAnalysisContent({
    required AsyncValue<AnalysisResult?> analysisAsync,
    required bool isLoading,
    required bool hasResult,
    required int recordCount,
  }) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI 正在分析您的消费数据...'),
          ],
        ),
      );
    }

    return analysisAsync.when(
      data: (result) {
        if (result == null) {
          // 没有分析结果，显示触发分析按钮
          return _buildEmptyState(recordCount);
        }
        return _buildAnalysisResult(result);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('分析失败: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _startAnalysis(),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空状态（未分析）
  Widget _buildEmptyState(int recordCount) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              recordCount > 0 ? '该月份尚未分析' : '该月份暂无记录',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              recordCount > 0
                  ? '点击下方按钮，让 AI 为您分析消费情况'
                  : '请先记录一些收支数据',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (recordCount > 0) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _startAnalysis(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('开始智能分析'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建分析结果
  Widget _buildAnalysisResult(AnalysisResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 健康评分卡片
          _buildScoreCard(result.score),
          const SizedBox(height: 16),

          // 总体评价
          _buildSectionCard(
            title: '总体评价',
            icon: Icons.summarize,
            content: result.summary,
          ),
          const SizedBox(height: 12),

          // 消费概况
          _buildSectionCard(
            title: '消费概况',
            icon: Icons.trending_up,
            content: result.overview,
          ),
          const SizedBox(height: 12),

          // 类别分析
          _buildSectionCard(
            title: '类别分析',
            icon: Icons.pie_chart,
            content: result.categoryAnalysis,
          ),
          const SizedBox(height: 12),

          // 智能建议
          _buildSuggestionsCard(result.suggestions),
          const SizedBox(height: 12),

          // 趋势洞察
          _buildSectionCard(
            title: '趋势洞察',
            icon: Icons.insights,
            content: result.trends,
          ),
          const SizedBox(height: 12),

          // 下月预测
          _buildSectionCard(
            title: '下月预测',
            icon: Icons.calendar_today,
            content: result.prediction,
          ),
          const SizedBox(height: 24),

          // 分析时间
          Center(
            child: Text(
              '分析时间: ${DateFormat('yyyy-MM-dd HH:mm').format(result.analyzedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建评分卡片
  Widget _buildScoreCard(int score) {
    Color scoreColor;
    String scoreText;
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreText = '优秀';
    } else if (score >= 60) {
      scoreColor = Colors.orange;
      scoreText = '良好';
    } else {
      scoreColor = Colors.red;
      scoreText = '需改善';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 圆形进度
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        '分',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '消费健康评分',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    scoreText,
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '基于您的收支数据和消费习惯综合评估',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建章节卡片
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建建议卡片
  Widget _buildSuggestionsCard(List<String> suggestions) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, size: 20, color: AppColors.brandPrimary),
              const SizedBox(width: 8),
              Text(
                '智能建议',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...suggestions.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8, top: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 开始分析
  Future<void> _startAnalysis() async {
    try {
      await ref.read(analysisResultProvider.notifier).analyze();
    } catch (e) {
      if (mounted) {
        TopNotification.error(context, '分析失败: $e');
      }
    }
  }

  /// 刷新分析
  Future<void> _refreshAnalysis() async {
    try {
      await ref.read(analysisResultProvider.notifier).refreshAnalysis();
      if (mounted) {
        TopNotification.success(context, '分析已更新');
      }
    } catch (e) {
      if (mounted) {
        TopNotification.error(context, '刷新失败: $e');
      }
    }
  }
}
