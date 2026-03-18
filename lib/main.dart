import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/database.dart';
import 'data/database/database_initializer.dart';
import 'data/local/preferences.dart';
import 'data/repositories/categories_repository.dart';
import 'data/repositories/web_categories_repository.dart';
import 'presentation/providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final preferencesService = PreferencesService(prefs);

  // 初始化默认分类（首次启动时）
  await _initializeDefaultCategories(preferencesService, prefs);

  runApp(
    ProviderScope(
      overrides: [
        // 覆盖 sharedPreferencesProvider，提供已初始化的实例
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}

/// 初始化默认分类
/// 在应用首次启动时插入预设分类数据
Future<void> _initializeDefaultCategories(
  PreferencesService preferencesService,
  SharedPreferences prefs,
) async {
  try {
    final isFirstLaunch = await preferencesService.isFirstLaunch();

    if (isFirstLaunch) {
      if (kDebugMode) {
        print('首次启动，初始化默认分类...');
      }

      if (kIsWeb) {
        // Web 平台使用 WebCategoriesRepository 初始化
        final webRepository = WebCategoriesRepository(prefs);
        await webRepository.initializeDefaultCategories();
      } else {
        // Native 平台使用 DatabaseInitializer 初始化
        final database = AppDatabase();
        final categoriesDao = database.categoriesDao;
        final categoriesRepository = CategoriesRepository(categoriesDao);
        final initializer = DatabaseInitializer(
          preferences: preferencesService,
          categoriesRepository: categoriesRepository,
        );
        await initializer.initialize();
      }

      if (kDebugMode) {
        print('默认分类初始化完成');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('初始化默认分类失败: $e');
    }
  }
}
