import 'package:flutter/material.dart';
import 'dart:math';

/// 响应式设计工具类
/// 提供统一的响应式约束、字体和间距处理

/// 屏幕尺寸断点定义
class ScreenBreakpoints {
  /// 小屏设备 (320px - 375px)
  static const double small = 375.0;
  
  /// 中等屏幕设备 (375px - 414px)  
  static const double medium = 414.0;
  
  /// 大屏设备 (414px+)
  static const double large = 600.0;
}

/// 响应式约束工具
/// 根据屏幕宽度提供合适的最大宽度和边距
class ResponsiveConstraints {
  /// 获取内容的最大宽度约束
  /// 在小屏幕上使用全宽，在大屏幕上限制最大宽度
  static BoxConstraints getContentConstraints(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    
    if (screenWidth >= ScreenBreakpoints.large) {
      // 大屏设备：限制最大宽度为 600px，居中显示
      return const BoxConstraints(maxWidth: 600);
    } else if (screenWidth >= ScreenBreakpoints.medium) {
      // 中等屏幕：限制最大宽度为 500px
      return const BoxConstraints(maxWidth: 500);
    } else {
      // 小屏设备：使用全宽
      return BoxConstraints(maxWidth: screenWidth);
    }
  }
  
  /// 获取水平边距
  /// 根据屏幕尺寸调整边距大小
  static double getHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    
    if (screenWidth >= ScreenBreakpoints.large) {
      return 32.0; // 大屏使用更大的边距
    } else if (screenWidth >= ScreenBreakpoints.medium) {
      return 24.0; // 中等屏幕使用标准边距
    } else {
      return 16.0; // 小屏使用较小的边距
    }
  }
  
  /// 获取垂直边距
  static double getVerticalPadding(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    
    if (screenHeight >= 800) {
      return 24.0; // 高屏幕使用更大的垂直边距
    } else if (screenHeight >= 600) {
      return 16.0; // 标准屏幕使用标准垂直边距
    } else {
      return 12.0; // 低屏幕使用较小的垂直边距
    }
  }
  
  /// 包装内容以应用响应式约束
  /// 自动处理居中和边距
  static Widget constrainedContent({
    required BuildContext context,
    required Widget child,
    bool center = true,
  }) {
    final constraints = getContentConstraints(context);
    final horizontalPadding = getHorizontalPadding(context);
    
    Widget content = Container(
      constraints: constraints,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: child,
    );
    
    if (center && MediaQuery.sizeOf(context).width >= ScreenBreakpoints.large) {
      // 在大屏上居中显示
      content = Center(child: content);
    }
    
    return content;
  }
}

/// 响应式字体工具
/// 根据屏幕尺寸和DPI调整字体大小
class ResponsiveText {
  /// 获取响应式字体大小
  /// baseSize 是基准字体大小，会根据屏幕进行缩放
  static double getResponsiveFontSize(
    BuildContext context, {
    required double baseSize,
    double minSize = 10.0,
    double maxSize = 24.0,
    bool scaleWithTextScaleFactor = true,
  }) {
    final textScaleFactor = scaleWithTextScaleFactor 
        ? MediaQuery.textScaleFactorOf(context) 
        : 1.0;
    
    // 先应用系统文本缩放
    double scaledSize = baseSize * textScaleFactor;
    
    // 根据屏幕尺寸进行额外缩放
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenDiagonal = sqrt(screenWidth * screenWidth + screenHeight * screenHeight);
    
    double screenSizeFactor = 1.0;
    if (screenDiagonal >= 800) {
      screenSizeFactor = 1.05; // 大屏稍微放大（降低系数）
    } else if (screenDiagonal <= 500) {
      screenSizeFactor = 0.95; // 小屏稍微缩小（降低系数）
    }
    
    scaledSize *= screenSizeFactor;
    
    // 限制在最小和最大范围内（缩小了 maxSize）
    return scaledSize.clamp(minSize, maxSize);
  }
  
  /// 创建响应式TextStyle
  static TextStyle responsiveStyle({
    required BuildContext context,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    String? fontFamily,
  }) {
    return TextStyle(
      fontSize: fontSize != null 
          ? getResponsiveFontSize(context, baseSize: fontSize)
          : null,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      fontFamily: fontFamily,
    );
  }
}

/// 响应式间距工具
/// 根据屏幕尺寸调整间距大小
class ResponsiveSpacing {
  /// 获取响应式间距
  /// baseSpacing 是基准间距，会根据屏幕进行缩放
  static double getResponsiveSpacing(
    BuildContext context, {
    required double baseSpacing,
    double minSpacing = 4.0,
    double maxSpacing = 48.0,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenDiagonal = sqrt(screenWidth * screenWidth + screenHeight * screenHeight);
    
    double spacingFactor = 1.0;
    if (screenDiagonal >= 800) {
      spacingFactor = 1.2; // 大屏增加间距
    } else if (screenDiagonal <= 500) {
      spacingFactor = 0.8; // 小屏减少间距
    }
    
    final responsiveSpacing = baseSpacing * spacingFactor;
    return responsiveSpacing.clamp(minSpacing, maxSpacing);
  }
  
  /// 创建响应式EdgeInsets
  static EdgeInsetsGeometry responsivePadding({
    required BuildContext context,
    double all = 0,
    double vertical = 0,
    double horizontal = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
    double left = 0,
  }) {
    return EdgeInsets.fromLTRB(
      left + horizontal + all,
      top + vertical + all,
      right + horizontal + all,
      bottom + vertical + all,
    ).copyWith(
      left: getResponsiveSpacing(context, baseSpacing: left + horizontal + all),
      top: getResponsiveSpacing(context, baseSpacing: top + vertical + all),
      right: getResponsiveSpacing(context, baseSpacing: right + horizontal + all),
      bottom: getResponsiveSpacing(context, baseSpacing: bottom + vertical + all),
    );
  }
  
  /// 创建响应式SizedBox
  static SizedBox responsiveSizedBox({
    required BuildContext context,
    double width = 0,
    double height = 0,
  }) {
    return SizedBox(
      width: width > 0 ? getResponsiveSpacing(context, baseSpacing: width) : null,
      height: height > 0 ? getResponsiveSpacing(context, baseSpacing: height) : null,
    );
  }
}