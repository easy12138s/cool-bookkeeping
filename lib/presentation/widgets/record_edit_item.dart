import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/parsed_result.dart';

/// 单条记录编辑项
/// 支持展开/收起式编辑
class RecordEditItem extends StatefulWidget {
  final int index;
  final ParsedResult result;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final Function(ParsedResult) onUpdate;
  final VoidCallback onDelete;

  const RecordEditItem({
    super.key,
    required this.index,
    required this.result,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<RecordEditItem> createState() => _RecordEditItemState();
}

class _RecordEditItemState extends State<RecordEditItem> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedCategory;
  late String _selectedType;

  final List<String> _expenseCategories = ['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
  final List<String> _incomeCategories = ['工资', '奖金', '投资', '兼职', '礼金', '其他'];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.result.amount?.toString() ?? '',
    );
    _noteController = TextEditingController(
      text: widget.result.note ?? '',
    );
    _selectedCategory = widget.result.category;
    _selectedType = widget.result.type;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isExpanded ? AppColors.brandPrimary : AppColors.divider,
          width: widget.isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // 收起状态：显示摘要
          if (!widget.isExpanded) _buildCollapsedView(),
          
          // 展开状态：显示完整编辑表单
          if (widget.isExpanded) _buildExpandedView(),
        ],
      ),
    );
  }

  /// 构建收起状态视图
  Widget _buildCollapsedView() {
    return ListTile(
      onTap: widget.onExpandToggle,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _selectedType == '收入' 
              ? AppColors.income.withValues(alpha: 0.1)
              : AppColors.expense.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _selectedType == '收入' ? Icons.arrow_upward : Icons.arrow_downward,
          color: _selectedType == '收入' ? AppColors.income : AppColors.expense,
        ),
      ),
      title: Row(
        children: [
          Text(
            '${widget.result.note ?? '记录'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _selectedCategory,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        _selectedType,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.result.amount != null ? '¥${widget.result.amount}' : '待填写',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: widget.result.amount != null 
                  ? (_selectedType == '收入' ? AppColors.income : AppColors.expense)
                  : AppColors.textDisabled,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  /// 构建展开状态视图
  Widget _buildExpandedView() {
    final categories = _selectedType == '收入' ? _incomeCategories : _expenseCategories;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部：标题和操作按钮
          Row(
            children: [
              const Icon(
                Icons.edit,
                size: 20,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 8),
              const Text(
                '编辑记录',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // 删除按钮
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // 收起按钮
              IconButton(
                onPressed: widget.onExpandToggle,
                icon: const Icon(Icons.expand_less, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 金额输入
          _buildAmountField(),
          
          const SizedBox(height: 16),
          
          // 类型选择
          _buildTypeSelector(),
          
          const SizedBox(height: 16),
          
          // 类别选择
          _buildCategorySelector(categories),
          
          const SizedBox(height: 16),
          
          // 备注输入
          _buildNoteField(),
        ],
      ),
    );
  }

  /// 构建金额输入字段
  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '金额',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '请输入金额',
            prefixText: '¥ ',
            prefixStyle: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.brandPrimary),
            ),
          ),
          onChanged: (_) => _updateResult(),
        ),
      ],
    );
  }

  /// 构建类型选择器
  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '类型',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTypeButton('支出', AppColors.expense),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeButton('收入', AppColors.income),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建类型按钮
  Widget _buildTypeButton(String type, Color color) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          // 切换类型时，重置类别为"其他"
          _selectedCategory = '其他';
        });
        _updateResult();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == '收入' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              type,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建类别选择器
  Widget _buildCategorySelector(List<String> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '类别',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                _updateResult();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.brandPrimary.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.brandPrimary : AppColors.divider,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建备注输入字段
  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备注',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          decoration: InputDecoration(
            hintText: '添加备注（可选）',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.brandPrimary),
            ),
          ),
          onChanged: (_) => _updateResult(),
        ),
      ],
    );
  }

  /// 更新结果
  void _updateResult() {
    final amount = double.tryParse(_amountController.text);
    widget.onUpdate(ParsedResult(
      amount: amount,
      category: _selectedCategory,
      type: _selectedType,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      rawText: widget.result.rawText,
      time: widget.result.time,
    ));
  }
}
