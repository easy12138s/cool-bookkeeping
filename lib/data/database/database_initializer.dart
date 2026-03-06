import 'package:uuid/uuid.dart';

import '../../core/constants/default_categories.dart';
import '../../data/local/preferences.dart';
import '../../data/models/category_model.dart';
import '../../data/repositories/categories_repository.dart';

/// 数据库初始化器
/// 负责应用首次启动时的数据初始化工作
class DatabaseInitializer {
  final PreferencesService _preferences;
  final CategoriesRepository _categoriesRepository;

  DatabaseInitializer({
    required PreferencesService preferences,
    required CategoriesRepository categoriesRepository,
  })  : _preferences = preferences,
        _categoriesRepository = categoriesRepository;

  /// 初始化数据库
  /// 检查是否首次启动，如果是则插入预设类别数据
  Future<void> initialize() async {
    final isFirstLaunch = await _preferences.isFirstLaunch();

    if (isFirstLaunch) {
      await _insertDefaultCategories();
      await _preferences.setFirstLaunch(false);
    }
  }

  /// 插入预设类别数据
  /// 将 DefaultCategories 中的数据转换为 CategoryModel 并插入数据库
  Future<void> _insertDefaultCategories() async {
    final defaultCategories = DefaultCategories.allCategories;
    final categoryModels = <CategoryModel>[];

    for (var i = 0; i < defaultCategories.length; i++) {
      final category = defaultCategories[i];
      categoryModels.add(
        CategoryModel(
          id: const Uuid().v4(),
          name: category['name'] as String,
          icon: category['icon'] as String,
          type: category['type'] as int,
          isPreset: true,
          isEnabled: true,
          sortOrder: i,
        ),
      );
    }

    await _categoriesRepository.insertDefaultCategories(categoryModels);
  }
}
