import 'package:flutter/material.dart';

/// 应用颜色常量定义
class AppColors {
  AppColors._();

  /// 品牌主色 - 深紫色
  static const Color brandPrimary = Color(0xFF6B4EFF);

  /// 品牌浅色
  static const Color brandLight = Color(0xFF9B8AFF);

  /// 品牌深色
  static const Color brandDark = Color(0xFF4A3BCC);

  /// 支出颜色 - 红色
  static const Color expense = Color(0xFFFF6B6B);
  static const Color expenseColor = Color(0xFFFF6B6B); // 向后兼容

  /// 收入颜色 - 绿色
  static const Color income = Color(0xFF51CF66);
  static const Color incomeColor = Color(0xFF51CF66); // 向后兼容

  /// 禁用文字颜色
  static const Color textDisabled = Color(0xFFADB5BD);

  /// 背景色
  static const Color background = Color(0xFFF8F9FA);

  /// 表面色
  static const Color surface = Colors.white;

  /// 错误色
  static const Color error = Color(0xFFDC3545);

  /// 成功色
  static const Color success = Color(0xFF51CF66);

  /// 品牌次色
  static const Color brandSecondary = Color(0xFF9B8AFF);

  /// 文字主色
  static const Color textPrimary = Color(0xFF212529);

  /// 文字次色
  static const Color textSecondary = Color(0xFF6C757D);

  /// 分割线颜色
  static const Color divider = Color(0xFFE9ECEF);
}
