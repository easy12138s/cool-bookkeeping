/// 应用常量定义
/// 
/// 包含应用名称、版本、各种限制值和超时配置
class AppConstants {
  AppConstants._();

  /// 应用名称
  static const String appName = '酷记';

  /// 应用版本
  static const String appVersion = '1.0.0';

  /// 默认分页大小
  static const int defaultPageSize = 20;

  /// 备注最大长度
  static const int maxRecordNoteLength = 200;

  /// 类别名称最大长度
  static const int maxCategoryNameLength = 20;

  /// 默认货币符号
  static const String defaultCurrency = '¥';

  /// 语音识别超时秒数
  static const int speechTimeoutSeconds = 60;

  /// API 请求超时秒数
  static const int apiTimeoutSeconds = 30;
}
