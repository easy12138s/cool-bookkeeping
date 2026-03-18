import 'package:flutter/material.dart';

import 'responsive.dart';

/// 响应式间距系统
/// 提供统一的间距定义，支持响应式调整
class AppSpacing {
  AppSpacing._();

  /// 极小间距 (4px)
  static double xs(BuildContext context) => 
      ResponsiveSpacing.getResponsiveSpacing(context, baseSpacing: 4.0);

  /// 小间距 (8px)
  static double sm(BuildContext context) => 
      ResponsiveSpacing.getResponsiveSpacing(context, baseSpacing: 8.0);

  /// 中等间距 (16px)
  static double md(BuildContext context) => 
      ResponsiveSpacing.getResponsiveSpacing(context, baseSpacing: 16.0);

  /// 大间距 (24px)
  static double lg(BuildContext context) => 
      ResponsiveSpacing.getResponsiveSpacing(context, baseSpacing: 24.0);

  /// 超大间距 (32px)
  static double xl(BuildContext context) => 
      ResponsiveSpacing.getResponsiveSpacing(context, baseSpacing: 32.0);

  /// 创建响应式EdgeInsets
  static EdgeInsetsGeometry all(BuildContext context, double spacing) =>
      ResponsiveSpacing.responsivePadding(
        context: context,
        all: spacing,
      );

  static EdgeInsetsGeometry horizontal(BuildContext context, double spacing) =>
      ResponsiveSpacing.responsivePadding(
        context: context,
        horizontal: spacing,
      );

  static EdgeInsetsGeometry vertical(BuildContext context, double spacing) =>
      ResponsiveSpacing.responsivePadding(
        context: context,
        vertical: spacing,
      );

  static EdgeInsetsGeometry symmetric({
    required BuildContext context,
    double? horizontal,
    double? vertical,
  }) =>
      ResponsiveSpacing.responsivePadding(
        context: context,
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );

  static EdgeInsetsGeometry only({
    required BuildContext context,
    double top = 0,
    double right = 0,
    double bottom = 0,
    double left = 0,
  }) =>
      ResponsiveSpacing.responsivePadding(
        context: context,
        top: top,
        right: right,
        bottom: bottom,
        left: left,
      );

  /// 创建响应式SizedBox
  static SizedBox width(BuildContext context, double width) =>
      ResponsiveSpacing.responsiveSizedBox(context: context, width: width);

  static SizedBox height(BuildContext context, double height) =>
      ResponsiveSpacing.responsiveSizedBox(context: context, height: height);

  static SizedBox size(BuildContext context, double size) =>
      ResponsiveSpacing.responsiveSizedBox(
        context: context,
        width: size,
        height: size,
      );
}