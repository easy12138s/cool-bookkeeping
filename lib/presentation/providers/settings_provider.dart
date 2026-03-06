import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/local/preferences.dart';
import 'providers.dart';

part 'settings_provider.freezed.dart';

/// 设置状态类
/// 包含应用配置的所有设置项
@freezed
class SettingsState with _$SettingsState {
  const factory SettingsState({
    /// API 密钥
    String? apiKey,

    /// API 基础 URL
    String? apiBaseUrl,

    /// 自动保存是否启用
    @Default(false) bool autoSaveEnabled,

    /// 是否首次启动
    @Default(true) bool isFirstLaunch,
  }) = _SettingsState;
}

/// Settings Notifier
/// 管理应用设置的状态和业务逻辑
class SettingsNotifier extends StateNotifier<SettingsState> {
  final PreferencesService _preferences;

  SettingsNotifier(this._preferences) : super(const SettingsState()) {
    loadSettings();
  }

  /// 加载所有设置
  /// 从 PreferencesService 读取配置
  Future<void> loadSettings() async {
    try {
      final apiKey = await _preferences.getApiKey();
      final apiBaseUrl = await _preferences.getApiBaseUrl();
      final autoSaveEnabled = await _preferences.getAutoSaveEnabled();
      final isFirstLaunch = await _preferences.isFirstLaunch();

      state = SettingsState(
        apiKey: apiKey,
        apiBaseUrl: apiBaseUrl,
        autoSaveEnabled: autoSaveEnabled,
        isFirstLaunch: isFirstLaunch,
      );
    } catch (e) {
      // 保持默认状态
      state = const SettingsState();
    }
  }

  /// 设置 API 密钥
  /// [value] API 密钥值，null 表示清除
  Future<void> setApiKey(String? value) async {
    await _preferences.setApiKey(value);
    state = state.copyWith(apiKey: value);
  }

  /// 设置 API 基础 URL
  /// [value] API 基础 URL，null 表示清除
  Future<void> setApiBaseUrl(String? value) async {
    await _preferences.setApiBaseUrl(value);
    state = state.copyWith(apiBaseUrl: value);
  }

  /// 设置自动保存状态
  /// [enabled] 是否启用自动保存
  Future<void> setAutoSaveEnabled(bool enabled) async {
    await _preferences.setAutoSaveEnabled(enabled);
    state = state.copyWith(autoSaveEnabled: enabled);
  }

  /// 标记首次启动完成
  Future<void> markFirstLaunchComplete() async {
    await _preferences.setFirstLaunch(false);
    state = state.copyWith(isFirstLaunch: false);
  }
}

/// Settings Provider
/// 提供 SettingsNotifier 实例
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final preferences = ref.watch(preferencesProvider);
    return SettingsNotifier(preferences);
  },
);
