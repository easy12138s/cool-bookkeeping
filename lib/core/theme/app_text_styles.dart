import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'responsive.dart';

/// 应用文字样式定义
class AppTextStyles {
  AppTextStyles._();

  /// 获取响应式文字样式
  /// 根据上下文返回适配当前屏幕的样式
  static TextStyle getDisplayLarge(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle getDisplayMedium(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle getHeadlineLarge(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle getHeadlineMedium(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle getTitleLarge(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle getTitleMedium(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle getBodyLarge(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle getBodyMedium(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle getLabelLarge(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle getLabelMedium(BuildContext context) {
    return ResponsiveText.responsiveStyle(
      context: context,
      fontSize: 12,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    );
  }

  /// 兼容旧的静态样式（用于不需要响应式的场景）
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
}
