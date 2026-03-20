import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/record_model.dart';
import '../../providers/categories_provider.dart';
import '../../providers/records_provider.dart';

/// 统计页面
/// 展示收支统计图表与类别分析
class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _timeRangeIndex = 1; // 0=周, 1=月, 2=年
  final List<String> _timeRanges = ['本周', '本月', '本年'];
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

  String get _currentTimeLabel => _timeRanges[_timeRangeIndex];

  (DateTime, DateTime) _getDateRange() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_timeRangeIndex) {
      case 0:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 1:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 2:
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    return (startDate, now);
  }

  /// 格式化金额（千位分隔符）
  String _formatAmount(double amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(2)}亿';
    }
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(2)}万';
    }
    final str = amount.toStringAsFixed(2);
    final parts = str.split('.');
    final intPart = parts[0];
    final result = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(intPart[i]);
    }
    return '${result.toString()}.${parts[1]}';
  }

  /// 格式化百分比
  String _formatPercent(double percentage) {
    final p = (percentage * 100).toStringAsFixed(1);
    if (p.endsWith('.0')) {
      return '${p.substring(0, p.length - 2)}%';
    }
    return '$p%';
  }

  /// 格式化短金额
  String _formatAmountShort(double value) {
    if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}w';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(recordsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.brandPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.brandPrimary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: '支出'),
                Tab(text: '收入'),
              ],
            ),
          ),
          Expanded(
            child: recordsAsync.when(
              data: (records) => categoriesAsync.when(
                data: (categories) => TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatisticsView(records, categories, 0),
                    _buildStatisticsView(records, categories, 1),
                  ],
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('加载类别失败: $error')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('加载记录失败: $error')),
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
    final filteredRecords = _filterRecordsByTimeRange(records, type);

    if (filteredRecords.isEmpty) {
      return _buildEmptyState(type);
    }

    final totalAmount = filteredRecords.fold<double>(
      0,
      (sum, record) => sum + record.amount,
    );

    final categoryStats = _calculateCategoryStats(
      filteredRecords,
      categories,
      totalAmount,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // 核心数据卡片
          _buildTotalCard(totalAmount, type),
          const SizedBox(height: 16),
          // 图表类型筛选（第一行）
          _buildChartTypeRow(),
          const SizedBox(height: 8),
          // 时间范围筛选（第二行）
          _buildTimeRangeRow(),
          const SizedBox(height: 20),
          // 图表
          if (_chartTypeIndex == 0)
            _buildPieChart(categoryStats)
          else
            _buildBarChart(categoryStats, type),
          const SizedBox(height: 20),
          // 类别明细列表
          _buildCategoryList(categoryStats, totalAmount),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建图表类型筛选行
  Widget _buildChartTypeRow() {
    return Row(
      children: [
        Text(
          '图表类型',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        ..._chartTypes.asMap().entries.map((entry) {
          final isSelected = entry.key == _chartTypeIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _chartTypeIndex = entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      entry.key == 0 ? Icons.pie_chart : Icons.bar_chart,
                      size: 13,
                      color: isSelected
                          ? AppColors.brandPrimary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.brandPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 构建时间范围筛选行
  Widget _buildTimeRangeRow() {
    return Row(
      children: [
        Text(
          '时间范围',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        ..._timeRanges.asMap().entries.map((entry) {
          final isSelected = entry.key == _timeRangeIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _timeRangeIndex = entry.key),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandPrimary.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.divider,
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? AppColors.brandPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 构建总金额卡片
  Widget _buildTotalCard(double totalAmount, int type) {
    final isExpense = type == 0;
    final label = isExpense ? '总支出' : '总收入';
    final formattedAmount = '¥${_formatAmount(totalAmount)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary,
            AppColors.brandPrimary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_currentTimeLabel$label',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Icon(
                isExpense ? Icons.trending_down : Icons.trending_up,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 金额 — 使用 Text 直接传入格式化后的字符串
          Text(
            formattedAmount,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
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

    final colors = _getCategoryColors();

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: stats.take(8).toList().asMap().entries.map((e) {
            final index = e.key;
            final stat = e.value;
            final color = colors[index % colors.length];
            return PieChartSectionData(
              color: color,
              value: stat.amount,
              title: _formatPercent(stat.percentage),
              radius: 55,
              titleStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建柱状图
  Widget _buildBarChart(List<CategoryStat> stats, int type) {
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = type == 0 ? AppColors.brandPrimary : AppColors.incomeColor;
    final displayStats = stats.take(8).toList();
    final maxAmount =
        displayStats.map((s) => s.amount).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
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
                  '${stat.category.name}\n¥${_formatAmount(stat.amount)}',
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
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(
                        _getIconData(displayStats[index].category.icon),
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 28,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatAmountShort(value),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                  width: 18,
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
    );
  }

  /// 构建类别明细列表
  Widget _buildCategoryList(List<CategoryStat> stats, double totalAmount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '类别明细',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          final color =
              _getCategoryColors()[index % _getCategoryColors().length];
          return _buildCategoryItem(stat, color);
        }),
      ],
    );
  }

  /// 构建类别项
  Widget _buildCategoryItem(CategoryStat stat, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                // 类别图标
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIconData(stat.category.icon),
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                // 类别名称
                Expanded(
                  child: Text(
                    stat.category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 百分比
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatPercent(stat.percentage),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 金额
                Text(
                  '¥${_formatAmount(stat.amount)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无$typeText记录',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '切换时间范围试试吧',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  List<RecordModel> _filterRecordsByTimeRange(
    List<RecordModel> records,
    int type,
  ) {
    final (startDate, endDate) = _getDateRange();

    return records.where((record) {
      return record.type == type &&
          record.createdAt.isAfter(startDate) &&
          record.createdAt
              .isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

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

  List<Color> _getCategoryColors() {
    return [
      AppColors.brandPrimary,
      AppColors.brandSecondary,
      const Color(0xFFFF6B6B),
      const Color(0xFF51CF66),
      const Color(0xFFFFAB40),
      const Color(0xFF7C4DFF),
      const Color(0xFF00BCD4),
      const Color(0xFFFF4081),
      const Color(0xFF009688),
      const Color(0xFFFF9800),
    ];
  }

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
