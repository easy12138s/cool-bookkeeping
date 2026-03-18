import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/responsive.dart';
import '../../data/models/record_model.dart';
import '../providers/categories_provider.dart';
import '../providers/records_provider.dart';
import 'top_notification.dart';

/// 手动记账底部表单
/// 从底部弹出的表单，用于手动输入记账记录
class ManualEntrySheet extends ConsumerStatefulWidget {
  const ManualEntrySheet({super.key});

  @override
  ConsumerState<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends ConsumerState<ManualEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int _type = 0; // 0=支出, 1=收入
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 加载类别列表
    Future.microtask(() {
      ref.read(categoriesProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      TopNotification.warning(context, '请选择类别');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final amount = double.parse(_amountController.text);
      final record = RecordModel(
        id: const Uuid().v4(),
        amount: amount,
        categoryId: _selectedCategoryId!,
        type: _type,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        createdAt: _selectedDate,
        updatedAt: DateTime.now(),
      );

      await ref.read(recordsProvider.notifier).addRecord(record);

      if (mounted) {
        TopNotification.success(context, '记账成功');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        TopNotification.error(context, '保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    final containerHeight = ResponsiveSpacing.getResponsiveSpacing(
      context,
      baseSpacing: 480.0,
      minSpacing: 400.0,
      maxSpacing: 560.0,
    );

    final headerPadding = AppSpacing.symmetric(
      context: context,
      horizontal: 16,
      vertical: 12,
    );

    final contentPadding = AppSpacing.symmetric(
      context: context,
      horizontal: 16,
      vertical: 16,
    );

    final spacingMd = AppSpacing.md(context);
    final spacingLg = AppSpacing.lg(context);

    return Container(
      height: containerHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            padding: headerPadding,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('取消', style: AppTextStyles.getBodyMedium(context)),
                ),
                Text(
                  '手动记账',
                  style: AppTextStyles.getTitleMedium(context),
                ),
                TextButton(
                  onPressed: _isSaving ? null : _saveRecord,
                  child: _isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('保存', style: AppTextStyles.getBodyMedium(context)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: contentPadding,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
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
                        onSelectionChanged: (value) {
                          setState(() {
                            _type = value.first;
                            _selectedCategoryId = null;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: spacingLg),

                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: '金额',
                        prefixText: '¥ ',
                        border: OutlineInputBorder(),
                      ),
                      style: AppTextStyles.getBodyLarge(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入金额';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return '请输入有效的金额';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: spacingMd),

                    categoriesAsync.when(
                      data: (categories) {
                        final filteredCategories = categories
                            .where((c) => c.type == _type && c.isEnabled)
                            .toList();

                        if (filteredCategories.isEmpty) {
                          return Container(
                            padding: contentPadding,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.orange),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _type == 0
                                        ? '暂无支出类别，请检查数据初始化'
                                        : '暂无收入类别，请检查数据初始化',
                                    style: TextStyle(color: Colors.orange.shade800),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          decoration: InputDecoration(
                            labelText: '类别',
                            border: OutlineInputBorder(),
                          ),
                          hint: Text('选择类别', style: AppTextStyles.getBodyMedium(context)),
                          items: filteredCategories.map((category) {
                            return DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                children: [
                                  Icon(
                                    _getIconData(category.icon),
                                    size: 20,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 8),
                                  Text(category.name, style: AppTextStyles.getBodyMedium(context)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedCategoryId = value);
                          },
                          validator: (value) {
                            if (value == null) {
                              return '请选择类别';
                            }
                            return null;
                          },
                        );
                      },
                      loading: () => Center(
                        child: Padding(
                          padding: contentPadding,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, stackTrace) {
                        debugPrint('类别加载错误: $error');
                        debugPrint('堆栈跟踪: $stackTrace');

                        return Container(
                          padding: contentPadding,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red.shade50,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.error, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    '加载类别失败',
                                    style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '错误信息: $error',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  ref.read(categoriesProvider.notifier).loadCategories();
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('重试'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: spacingMd),

                    InkWell(
                      onTap: _selectDateTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '时间',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(_formatDateTime(_selectedDate), style: AppTextStyles.getBodyMedium(context)),
                      ),
                    ),
                    SizedBox(height: spacingMd),

                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: '备注（可选）',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      style: AppTextStyles.getBodyMedium(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

/// 显示手动记账表单
void showManualEntrySheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ManualEntrySheet(),
  );
}
