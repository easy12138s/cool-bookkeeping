import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/record_model.dart';
import '../../providers/categories_provider.dart';
import '../../providers/records_provider.dart';

/// 统计页面
/// 显示收支统计图表和类别分析
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _timeRangeIndex = 1; // 0=周, 1=月, 2=年
  final List<String> _timeRanges = ['周', '月', '年'];
  int _chartTypeIndex = 0; // 0=饼图, 1=柱状图
  final List<String> _chartTypes = ['饼图', '柱状图'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '支出'),
            Tab(text: '收入'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 时间范围选择器
          _buildTimeRangeSelector(),
          // 统计内容
          Expanded(
            child: recordsAsync.when(
              data: (records) => categoriesAsync.when(
                data: (categories) => TabBarView(
                  controller: _tabController,
                  children: [
                    // 支出统计
                    _buildStatisticsView(records, categories, 0),
                    // 收入统计
                    _buildStatisticsView(records, categories, 1),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('加载类别失败: $error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('加载记录失败: $error')),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建时间范围选择器
  Widget _buildTimeRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 图表类型切换
          Expanded(
            child: SegmentedButton<int>(
              segments: _chartTypes.asMap().entries.map((entry) {
                return ButtonSegment(
                  value: entry.key,
                  label: Text(entry.value),
                  icon: Icon(
                    entry.key == 0 ? Icons.pie_chart : Icons.bar_chart,
                    size: 16,
                  ),
                );
              }).toList(),
              selected: {_chartTypeIndex},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _chartTypeIndex = newSelection.first;
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          // 时间范围切换
          Expanded(
            child: SegmentedButton<int>(
              segments: _timeRanges.asMap().entries.map((entry) {
                return ButtonSegment(
                  value: entry.key,
                  label: Text(entry.value),
                );
              }).toList(),
              selected: {_timeRangeIndex},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _timeRangeIndex = newSelection.first;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计视图
  Widget _buildStatisticsView(
    List<RecordModel> records,
    List<CategoryModel> categories,
    int type,
  ) {
    // 筛选指定时间范围和类型的记录
    final filteredRecords = _filterRecordsByTimeRange(records, type);

    if (filteredRecords.isEmpty) {
      return _buildEmptyState(type);
    }

    // 计算统计数据
    final totalAmount = filteredRecords.fold<double>(
      0,
      (sum, record) => sum + record.amount,
    );

    // 按类别分组统计
    final categoryStats = _calculateCategoryStats(
      filteredRecords,
      categories,
      totalAmount,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 总金额卡片
          _buildTotalCard(totalAmount, type),
          const SizedBox(height: 24),
          // 根据图表类型显示
          if (_chartTypeIndex == 0)
            _buildPieChart(categoryStats)
          else
            _buildBarChart(categoryStats, type),
          const SizedBox(height: 24),
          // 类别列表
          _buildCategoryList(categoryStats, totalAmount),
        ],
      ),
    );
  }

  /// 筛选记录
  List<RecordModel> _filterRecordsByTimeRange(
    List<RecordModel> records,
    int type,
  ) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_timeRangeIndex) {
      case 0: // 周
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 1: // 月
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 2: // 年
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return records.where((record) {
      return record.type == type &&
          record.createdAt.isAfter(startDate) &&
          record.createdAt.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  /// 计算类别统计
  List<CategoryStat> _calculateCategoryStats(
    List<RecordModel> records,
    List<CategoryModel> categories,
    double totalAmount,
  ) {
    final Map<String, double> amountMap = {};

    for (final record in records) {
      amountMap[record.categoryId] =
          (amountMap[record.categoryId] ?? 0) + record.amount;
    }

    final stats = amountMap.entries.map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => CategoryModel(
          id: entry.key,
          name: '未知',
          icon: 'help',
          type: 0,
          isPreset: true,
          isEnabled: true,
          sortOrder: 0,
        ),
      );

      return CategoryStat(
        category: category,
        amount: entry.value,
        percentage: totalAmount > 0 ? entry.value / totalAmount : 0,
      );
    }).toList();

    stats.sort((a, b) => b.amount.compareTo(a.amount));
    return stats;
  }

  /// 构建空状态
  Widget _buildEmptyState(int type) {
    final typeText = type == 0 ? '支出' : '收入';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无$typeText记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建总金额卡片
  Widget _buildTotalCard(double totalAmount, int type) {
    final color = type == 0 ? AppColors.expenseColor : AppColors.incomeColor;
    final label = type == 0 ? '总支出' : '总收入';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建饼图
  Widget _buildPieChart(List<CategoryStat> stats) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = [
      AppColors.brandPrimary,
      AppColors.brandSecondary,
      AppColors.expenseColor,
      AppColors.incomeColor,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    return Column(
      children: [
        Text(
          '分类占比',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: stats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                final color = colors[index % colors.length];

                return PieChartSectionData(
                  color: color,
                  value: stat.amount,
                  title: '${(stat.percentage * 100).toStringAsFixed(1)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建柱状图
  Widget _buildBarChart(List<CategoryStat> stats, int type) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = type == 0 ? AppColors.expenseColor : AppColors.incomeColor;
    final displayStats = stats.take(10).toList();
    final maxAmount = displayStats.map((s) => s.amount).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Text(
          'Top 10 分类',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAmount * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  tooltipPadding: const EdgeInsets.all(8),
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final stat = displayStats[group.x.toInt()];
                    return BarTooltipItem(
                      '${stat.category.name}\n¥${stat.amount.toStringAsFixed(2)}',
                      const TextStyle(color: Colors.white, fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < displayStats.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Icon(
                            _getIconData(displayStats[index].category.icon),
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 32,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatAmount(value),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxAmount / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: AppColors.divider,
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: displayStats.asMap().entries.map((entry) {
                final index = entry.key;
                final stat = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: stat.amount,
                      color: color,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// 格式化金额显示
  String _formatAmount(double value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}w';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  /// 构建类别列表
  Widget _buildCategoryList(List<CategoryStat> stats, double totalAmount) {
    final colors = [
      AppColors.brandPrimary,
      AppColors.brandSecondary,
      AppColors.expenseColor,
      AppColors.incomeColor,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '类别明细',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        ...stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final color = colors[index % colors.length];

          return _buildCategoryItem(stat, color);
        }),
      ],
    );
  }

  /// 构建类别项
  Widget _buildCategoryItem(CategoryStat stat, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // 颜色指示器
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // 图标
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconData(stat.category.icon),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // 类别名称和占比
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.category.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${(stat.percentage * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          // 金额
          Text(
            '¥${stat.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
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

/// 类别统计数据类
class CategoryStat {
  final CategoryModel category;
  final double amount;
  final double percentage;

  CategoryStat({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}
