import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences 键名常量
class _PreferenceKeys {
  static const String apiKey = 'api_key';
  static const String apiBaseUrl = 'api_base_url';
  static const String modelName = 'model_name';
  static const String autoSaveEnabled = 'auto_save_enabled';
  static const String firstLaunch = 'first_launch';
}

/// 默认模型名称
class _DefaultConfig {
  static const String modelName = 'qwen3.5-plus';
}

/// 本地偏好设置服务
/// 封装 SharedPreferences 操作，提供类型安全的配置读写
class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  /// 获取 API 密钥
  Future<String?> getApiKey() async {
    return _prefs.getString(_PreferenceKeys.apiKey);
  }

  /// 设置 API 密钥
  Future<void> setApiKey(String? value) async {
    if (value == null) {
      await _prefs.remove(_PreferenceKeys.apiKey);
    } else {
      await _prefs.setString(_PreferenceKeys.apiKey, value);
    }
  }

  /// 获取 API 基础 URL
  Future<String?> getApiBaseUrl() async {
    return _prefs.getString(_PreferenceKeys.apiBaseUrl);
  }

  /// 设置 API 基础 URL
  Future<void> setApiBaseUrl(String? value) async {
    if (value == null) {
      await _prefs.remove(_PreferenceKeys.apiBaseUrl);
    } else {
      await _prefs.setString(_PreferenceKeys.apiBaseUrl, value);
    }
  }

  /// 获取模型名称
  Future<String> getModelName() async {
    return _prefs.getString(_PreferenceKeys.modelName) ?? _DefaultConfig.modelName;
  }

  /// 设置模型名称
  Future<void> setModelName(String? value) async {
    if (value == null) {
      await _prefs.remove(_PreferenceKeys.modelName);
    } else {
      await _prefs.setString(_PreferenceKeys.modelName, value);
    }
  }

  /// 获取自动保存是否启用
  Future<bool> getAutoSaveEnabled() async {
    return _prefs.getBool(_PreferenceKeys.autoSaveEnabled) ?? false;
  }

  /// 设置自动保存是否启用
  Future<void> setAutoSaveEnabled(bool value) async {
    await _prefs.setBool(_PreferenceKeys.autoSaveEnabled, value);
  }

  /// 检查是否首次启动应用
  Future<bool> isFirstLaunch() async {
    return _prefs.getBool(_PreferenceKeys.firstLaunch) ?? true;
  }

  /// 设置首次启动状态
  Future<void> setFirstLaunch(bool value) async {
    await _prefs.setBool(_PreferenceKeys.firstLaunch, value);
  }
}
