import 'package:intl/intl.dart';

/// DateTime 扩展
/// 提供便捷的日期格式化和计算方法
extension DateExtensions on DateTime {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// 格式化为 "yyyy-MM-dd"
  String toFormattedString() {
    return _dateFormat.format(this);
  }

  /// 格式化为 "yyyy-MM-dd HH:mm"
  String toDateTimeString() {
    return _dateTimeFormat.format(this);
  }

  /// 判断是否为今天
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// 判断是否为昨天
  bool get isYesterday {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// 当天开始时间 (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day, 0, 0, 0);
  }

  /// 当天结束时间 (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59);
  }
}
