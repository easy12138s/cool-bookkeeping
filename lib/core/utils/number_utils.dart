import 'package:intl/intl.dart';

/// 数字工具类
/// 提供金额格式化、解析和计算功能
class NumberUtils {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '¥',
    decimalDigits: 2,
  );

  static final NumberFormat _simpleFormat = NumberFormat('#,##0.00');

  /// 格式化为货币格式 "¥1,234.56"
  static String formatAmount(double amount) {
    return _currencyFormat.format(amount);
  }

  /// 格式化为简单数字格式 "1,234.56"
  static String formatAmountSimple(double amount) {
    return _simpleFormat.format(amount);
  }

  /// 从文本解析金额
  /// 支持格式："1234.56", "1,234.56", "¥1,234.56"
  /// 解析失败返回 null
  static double? parseAmount(String text) {
    if (text.isEmpty) {
      return null;
    }

    // 移除货币符号、空格和千分位分隔符
    final cleaned = text
        .replaceAll('¥', '')
        .replaceAll('\$', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();

    if (cleaned.isEmpty) {
      return null;
    }

    try {
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// 四舍五入到两位小数
  static double roundToTwoDecimals(double value) {
    return (value * 100).round() / 100;
  }
}
