import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// 显示 Cupertino 风格的日期时间选择器
/// 从底部弹出的滚轮选择器，支持中文标签
///
/// [context] BuildContext
/// [initialDateTime] 初始选中的日期时间
/// [minimumYear] 最小年份，默认 2020
/// [maximumYear] 最大年份，默认 2030
/// 返回选中的 DateTime，如果取消则返回 null
Future<DateTime?> showCupertinoDatetimePicker({
  required BuildContext context,
  DateTime? initialDateTime,
  int minimumYear = 2020,
  int maximumYear = 2030,
}) async {
  final DateTime now = DateTime.now();
  final DateTime initial = initialDateTime ?? now;

  return await showCupertinoModalPopup<DateTime>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (BuildContext buildContext) {
      return _CupertinoDatetimePicker(
        initialDateTime: initial,
        minimumYear: minimumYear,
        maximumYear: maximumYear,
      );
    },
  );
}

/// Cupertino 日期时间选择器内部组件
class _CupertinoDatetimePicker extends StatefulWidget {
  final DateTime initialDateTime;
  final int minimumYear;
  final int maximumYear;

  const _CupertinoDatetimePicker({
    required this.initialDateTime,
    required this.minimumYear,
    required this.maximumYear,
  });

  @override
  State<_CupertinoDatetimePicker> createState() => _CupertinoDatetimePickerState();
}

class _CupertinoDatetimePickerState extends State<_CupertinoDatetimePicker> {
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.initialDateTime;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      color: AppColors.surface,
      child: Column(
        children: [
          // 顶部工具栏
          _buildToolbar(context),
          // 分割线
          Container(
            height: 1,
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
          // 日期时间选择器
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.dateAndTime,
              initialDateTime: _selectedDateTime,
              minimumYear: widget.minimumYear,
              maximumYear: widget.maximumYear,
              use24hFormat: true,
              backgroundColor: AppColors.surface,
              itemExtent: 40,
              onDateTimeChanged: (DateTime newDateTime) {
                setState(() {
                  _selectedDateTime = newDateTime;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建顶部工具栏
  Widget _buildToolbar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 取消按钮
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text(
                '取消',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 确定按钮
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_selectedDateTime),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '确定',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
