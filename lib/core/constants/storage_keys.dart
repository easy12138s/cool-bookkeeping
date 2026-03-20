/// SharedPreferences 存储键名定义
/// 
/// 统一管理本地存储的所有键名，避免硬编码和键名冲突
class StorageKeys {
  StorageKeys._();

  /// API Key 存储键
  static const String apiKey = 'api_key';

  /// API 基础 URL
  static const String apiBaseUrl = 'api_base_url';

  /// 模型名称
  static const String modelName = 'model_name';

  /// 自动保存开关
  static const String autoSaveEnabled = 'auto_save_enabled';

  /// 首次启动标记
  static const String firstLaunch = 'first_launch';

  /// 默认支出类别
  static const String defaultExpenseCategories = 'default_expense_categories';

  /// 默认收入类别
  static const String defaultIncomeCategories = 'default_income_categories';

  /// 百度语音 App ID
  static const String baiduSpeechAppId = 'baidu_speech_app_id';

  /// 百度语音 API Key
  static const String baiduSpeechApiKey = 'baidu_speech_api_key';

  /// 百度语音 Secret Key
  static const String baiduSpeechSecretKey = 'baidu_speech_secret_key';
}
