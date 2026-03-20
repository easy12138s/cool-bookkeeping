import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/database.dart';
import '../../data/database/daos/categories_dao.dart';
import '../../data/database/daos/records_dao.dart';
import '../../data/local/preferences.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/records_repository.dart';
import '../../data/repositories/web_categories_repository.dart';
import '../../data/repositories/web_records_repository.dart';
import '../../services/baidu_speech_service.dart';
import '../../services/services.dart';
import 'settings_provider.dart';

/// 数据库 Provider
/// Web 平台返回 null，使用 shared_preferences 替代
final databaseProvider = Provider<AppDatabase?>((ref) {
  if (kIsWeb) {
    return null;
  }
  return AppDatabase();
});

/// RecordsDao Provider
/// Web 平台返回 null
final recordsDaoProvider = Provider<RecordsDao?>((ref) {
  if (kIsWeb) {
    return null;
  }
  final database = ref.watch(databaseProvider);
  return database?.recordsDao;
});

/// CategoriesDao Provider
/// Web 平台返回 null
final categoriesDaoProvider = Provider<CategoriesDao?>((ref) {
  if (kIsWeb) {
    return null;
  }
  final database = ref.watch(databaseProvider);
  return database?.categoriesDao;
});

/// RecordsRepository Provider
/// Web 平台使用 WebRecordsRepository，Native 使用 RecordsRepository
final recordsRepositoryProvider = Provider<dynamic>((ref) {
  if (kIsWeb) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return WebRecordsRepository(prefs);
  }
  final recordsDao = ref.watch(recordsDaoProvider);
  if (recordsDao == null) {
    throw Exception('RecordsDao not available');
  }
  return RecordsRepository(recordsDao);
});

/// CategoriesRepository Provider
/// Web 平台使用 WebCategoriesRepository，Native 使用 CategoriesRepository
final categoriesRepositoryProvider = Provider<dynamic>((ref) {
  if (kIsWeb) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return WebCategoriesRepository(prefs);
  }
  final categoriesDao = ref.watch(categoriesDaoProvider);
  if (categoriesDao == null) {
    throw Exception('CategoriesDao not available');
  }
  return CategoriesRepository(categoriesDao);
});

/// SharedPreferences Provider
/// 异步初始化 SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be initialized before use. '
    'Override this provider in ProviderScope.',
  );
});

/// PreferencesService Provider
/// 依赖 sharedPreferencesProvider
final preferencesProvider = Provider<PreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PreferencesService(prefs);
});

/// SpeechService Provider
/// 提供语音识别服务单例
final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(service.dispose);
  return service;
});

/// 百度语音识别服务 Provider
final baiduSpeechServiceProvider = Provider<BaiduSpeechService>((ref) {
  final service = BaiduSpeechService();
  
  // 监听设置变化，自动配置百度语音服务
  final settings = ref.watch(settingsProvider);
  service.configure(
    appId: settings.baiduSpeechAppId,
    apiKey: settings.baiduSpeechApiKey,
    secretKey: settings.baiduSpeechSecretKey,
  );
  
  ref.onDispose(service.dispose);
  return service;
});

/// LlmService Provider
/// 依赖 preferencesProvider
final llmServiceProvider = Provider<LlmService>((ref) {
  final preferences = ref.watch(preferencesProvider);
  return LlmService(preferences: preferences);
});
