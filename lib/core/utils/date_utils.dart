import 'package:intl/intl.dart';

/// 日期工具类
/// 提供常用的日期格式化、计算和判断功能
class DateUtils {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// 格式化为 "yyyy-MM-dd"
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// 格式化为 "yyyy-MM-dd HH:mm"
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// 格式化为 "HH:mm"
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// 获取当天开始时间 (00:00:00)
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 0, 0, 0);
  }

  /// 获取当天结束时间 (23:59:59)
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// 获取当月第一天
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1, 0, 0, 0);
  }

  /// 获取当月最后一天
  static DateTime getEndOfMonth(DateTime date) {
    // 下月第0天即为本月最后一天
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final lastDay = nextMonth.subtract(const Duration(days: 1));
    return DateTime(lastDay.year, lastDay.month, lastDay.day, 23, 59, 59);
  }

  /// 判断是否为同一天
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 获取相对时间描述
  /// 今天、昨天、前天、X天前
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(targetDate).inDays;

    switch (difference) {
      case 0:
        return '今天';
      case 1:
        return '昨天';
      case 2:
        return '前天';
      default:
        if (difference > 0 && difference <= 30) {
          return '$difference天前';
        } else if (difference > 30) {
          return formatDate(date);
        } else {
          // 未来日期
          return formatDate(date);
        }
    }
  }
}
