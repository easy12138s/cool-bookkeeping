import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/category_model.dart';
import '../../data/models/record_model.dart';
import '../providers/categories_provider.dart';
import '../providers/records_provider.dart';
import '../providers/voice_bookkeeping_provider.dart';
import 'cupertino_datetime_picker.dart';

/// 显示确认卡片底部弹窗
/// [context] BuildContext
/// [ref] WidgetRef
Future<void> showConfirmationCard(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ConfirmationCard(),
  );
}

/// 确认卡片组件
/// 用于编辑和确认记账记录
class ConfirmationCard extends ConsumerStatefulWidget {
  const ConfirmationCard({super.key});

  @override
  ConsumerState<ConfirmationCard> createState() => _ConfirmationCardState();
}

class _ConfirmationCardState extends ConsumerState<ConfirmationCard> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String? _selectedCategory;
  int _type = 0; // 0 = 支出, 1 = 收入
  DateTime _selectedTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeFromParsedResult();
  }

  /// 从解析结果初始化表单数据
  void _initializeFromParsedResult() {
    final parsedResults = ref.read(parsedResultsProvider);
    // 使用第一条记录（向后兼容单条处理）
    final parsedResult = parsedResults.isNotEmpty ? parsedResults.first : null;

    _amountController = TextEditingController(
      text: parsedResult?.amount?.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: parsedResult?.note ?? '',
    );
    _selectedCategory = parsedResult?.category;
    _type = parsedResult?.type == '收入' ? 1 : 0;
    _selectedTime = parsedResult?.time ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      height: screenHeight * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 拖动指示器
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // 标题
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '确认记账信息',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          // 表单内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 类型切换
                  _buildTypeToggle(),
                  const SizedBox(height: 16),
                  // 金额输入
                  _buildAmountField(),
                  const SizedBox(height: 16),
                  // 类别选择
                  _buildCategoryField(categoriesAsync),
                  const SizedBox(height: 16),
                  // 时间选择
                  _buildTimeField(),
                  const SizedBox(height: 16),
                  // 备注输入
                  _buildNoteField(),
                ],
              ),
            ),
          ),
          // 操作按钮
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 构建类型切换组件
  Widget _buildTypeToggle() {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('支出'),
                icon: Icon(Icons.arrow_downward),
              ),
              ButtonSegment(
                value: 1,
                label: Text('收入'),
                icon: Icon(Icons.arrow_upward),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _type = newSelection.first;
                _selectedCategory = null;
              });
            },
          ),
        ),
      ],
    );
  }

  /// 构建金额输入框
  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '金额',
        prefixIcon: const Icon(Icons.attach_money),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: '请输入金额',
      ),
    );
  }

  /// 构建类别选择框
  Widget _buildCategoryField(AsyncValue<List<CategoryModel>> categoriesAsync) {
    return categoriesAsync.when(
      data: (categories) {
        final filteredCategories = categories
            .where((c) => c.type == _type && c.isEnabled)
            .toList();

        return DropdownButtonFormField<String>(
          value: filteredCategories.any((c) => c.name == _selectedCategory)
              ? _selectedCategory
              : null,
          decoration: InputDecoration(
            labelText: '类别',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          hint: const Text('选择类别'),
          items: filteredCategories.map((category) {
            return DropdownMenuItem(
              value: category.name,
              child: Row(
                children: [
                  Icon(
                    _getIconData(category.icon),
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(category.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (Object error, StackTrace stackTrace) => const Text('加载类别失败'),
    );
  }

  /// 构建时间选择框
  Widget _buildTimeField() {
    return InkWell(
      onTap: _selectDateTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '时间',
          prefixIcon: const Icon(Icons.access_time),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _formatDateTime(_selectedTime),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  /// 选择日期时间
  Future<void> _selectDateTime() async {
    final selected = await showCupertinoDatetimePicker(
      context: context,
      initialDateTime: _selectedTime,
      minimumYear: 2020,
      maximumYear: 2030,
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedTime = selected;
      });
    }
  }

  /// 格式化日期时间显示（中文格式）
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
        '${dateTime.hour.toString().padLeft(2, '0')}时'
        '${dateTime.minute.toString().padLeft(2, '0')}分';
  }

  /// 构建备注输入框
  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: '备注',
        prefixIcon: const Icon(Icons.notes),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        hintText: '添加备注（可选）',
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancel,
                child: const Text('取消'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _reparse,
                child: const Text('重新解析'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _confirm,
                child: const Text('确认保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 取消操作
  void _cancel() {
    Navigator.of(context).pop();
  }

  /// 重新解析
  void _reparse() {
    // 清空解析结果，触发重新解析
    ref.read(parsedResultsProvider.notifier).state = [];
    Navigator.of(context).pop();
  }

  /// 确认保存
  Future<void> _confirm() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('请输入有效的金额');
      return;
    }

    if (_selectedCategory == null) {
      _showError('请选择类别');
      return;
    }

    // 获取类别ID
    final categoriesAsync = ref.read(categoriesProvider);
    String? categoryId;
    categoriesAsync.whenData((categories) {
      final category = categories.firstWhere(
        (c) => c.name == _selectedCategory && c.type == _type,
      );
      categoryId = category.id;
    });

    if (categoryId == null) {
      _showError('类别信息无效');
      return;
    }

    // 创建记录
    final record = RecordModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      categoryId: categoryId!,
      type: _type,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      createdAt: _selectedTime,
    );

    // 保存记录
    await ref.read(recordsProvider.notifier).addRecord(record);

    // 清空解析结果
    ref.read(parsedResultsProvider.notifier).state = [];

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('记账成功')),
    );
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
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
