import 'package:flutter/material.dart';

/// BuildContext 扩展
/// 提供便捷的上下文访问方法
extension ContextExtensions on BuildContext {
  /// 快捷获取主题
  ThemeData get theme => Theme.of(this);

  /// 快捷获取颜色方案
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 快捷获取文字主题
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// 获取屏幕宽度
  double get screenWidth => MediaQuery.of(this).size.width;

  /// 获取屏幕高度
  double get screenHeight => MediaQuery.of(this).size.height;

  /// 判断是否暗色模式
  bool get isDarkMode =>
      MediaQuery.of(this).platformBrightness == Brightness.dark;
}
