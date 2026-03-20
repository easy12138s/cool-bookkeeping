import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 日期时间选择器主题配置
/// 提供统一的品牌色主题，用于美化日期和时间选择器
class DateTimePickerTheme {
  DateTimePickerTheme._();

  /// 日期选择器圆角半径
  static const double datePickerBorderRadius = 16.0;

  /// 时间选择器圆角半径
  static const double timePickerBorderRadius = 16.0;

  /// 获取日期选择器主题配置
  static ThemeData get datePickerTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: AppColors.brandPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.brandSecondary,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
      ),
    );
  }

  /// 获取时间选择器主题配置
  static ThemeData get timePickerTheme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: AppColors.brandPrimary,
        onPrimary: Colors.white,
        secondary: AppColors.brandSecondary,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
    );
  }
}
