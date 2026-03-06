import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/default_categories.dart';
import '../models/category_model.dart';

/// Web 平台分类 Repository
/// 使用 shared_preferences 存储 JSON 格式的分类数据
class WebCategoriesRepository {
  final SharedPreferences _prefs;
  static const String _categoriesKey = 'web_categories';
  static const String _initializedKey = 'web_categories_initialized';
  static const String _versionKey = 'web_categories_version';
  static const int _currentVersion = 2; // 数据版本号，用于强制重新初始化

  WebCategoriesRepository(this._prefs);

  /// 初始化预设分类
  Future<void> initializeDefaultCategories() async {
    try {
      // 检查版本号，如果版本不匹配则强制重新初始化
      final savedVersion = _prefs.getInt(_versionKey) ?? 0;
      final isInitialized = _prefs.getBool(_initializedKey) ?? false;

      if (isInitialized && savedVersion == _currentVersion) {
        // 验证已缓存的数据是否有效
        final isValid = await _validateCachedData();
        if (isValid) {
          return;
        }
        // 数据无效，需要重新初始化
      }

      // 清除旧数据
      await clearAllCategories();

      // 创建新的分类列表
      final categories = DefaultCategories.allCategories
          .map((c) => _categoryFromJson(c))
          .toList();

      await _saveCategories(categories);
      await _prefs.setBool(_initializedKey, true);
      await _prefs.setInt(_versionKey, _currentVersion);
    } catch (e, stackTrace) {
      throw Exception('初始化默认分类失败: $e\n$stackTrace');
    }
  }

  /// 验证已缓存的数据是否有效
  Future<bool> _validateCachedData() async {
    try {
      final jsonString = _prefs.getString(_categoriesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return false;
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      if (jsonList.isEmpty) {
        return false;
      }

      // 验证第一个元素是否包含所有必需字段
      final first = jsonList.first;
      if (first is! Map<String, dynamic>) {
        return false;
      }
      final requiredFields = ['id', 'name', 'icon', 'type', 'isPreset', 'isEnabled', 'sortOrder'];
      for (final field in requiredFields) {
        if (!first.containsKey(field)) {
          return false;
        }
      }

      // 尝试解析所有数据
      jsonList.map((json) => _categoryFromJson(json)).toList();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取所有分类
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      // 确保已初始化
      await initializeDefaultCategories();

      final jsonString = _prefs.getString(_categoriesKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => _categoryFromJson(json)).toList();
    } catch (e, stackTrace) {
      throw Exception('获取分类列表失败: $e\n$stackTrace');
    }
  }

  /// 从 JSON 创建 CategoryModel
  /// 处理类型转换和空值检查
  CategoryModel _categoryFromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw FormatException('Invalid category data format: $json');
    }

    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? 'category',
      type: json['type'] is int ? json['type'] : int.tryParse(json['type']?.toString() ?? '0') ?? 0,
      isPreset: json['isPreset'] is bool ? json['isPreset'] : json['isPreset']?.toString() == 'true',
      isEnabled: json['isEnabled'] is bool ? json['isEnabled'] : json['isEnabled']?.toString() != 'false',
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] : int.tryParse(json['sortOrder']?.toString() ?? '0') ?? 0,
    );
  }

  /// 根据类型获取分类
  Future<List<CategoryModel>> getCategoriesByType(int type) async {
    try {
      final categories = await getAllCategories();
      return categories.where((c) => c.type == type && c.isEnabled).toList();
    } catch (e) {
      throw Exception('获取分类列表失败: $e');
    }
  }

  /// 根据 ID 获取单个分类
  Future<CategoryModel?> getCategoryById(String id) async {
    try {
      final categories = await getAllCategories();
      try {
        return categories.firstWhere((c) => c.id == id);
      } catch (e) {
        return null;
      }
    } catch (e) {
      throw Exception('获取分类失败: $e');
    }
  }

  /// 插入新分类
  Future<void> insertCategory(CategoryModel model) async {
    try {
      final categories = await getAllCategories();
      categories.add(model);
      await _saveCategories(categories);
    } catch (e) {
      throw Exception('插入分类失败: $e');
    }
  }

  /// 更新分类
  Future<void> updateCategory(CategoryModel model) async {
    try {
      final categories = await getAllCategories();
      final index = categories.indexWhere((c) => c.id == model.id);
      if (index != -1) {
        categories[index] = model;
        await _saveCategories(categories);
      }
    } catch (e) {
      throw Exception('更新分类失败: $e');
    }
  }

  /// 删除分类
  /// 预设分类不能删除
  Future<void> deleteCategory(String id) async {
    try {
      final category = await getCategoryById(id);
      if (category == null) {
        throw Exception('分类不存在');
      }
      if (category.isPreset) {
        throw Exception('预设分类不能删除');
      }

      final categories = await getAllCategories();
      categories.removeWhere((c) => c.id == id);
      await _saveCategories(categories);
    } catch (e) {
      throw Exception('删除分类失败: $e');
    }
  }

  /// 批量插入默认分类
  Future<void> insertDefaultCategories(List<CategoryModel> models) async {
    try {
      final categories = await getAllCategories();
      categories.addAll(models);
      await _saveCategories(categories);
    } catch (e) {
      throw Exception('批量插入分类失败: $e');
    }
  }

  /// 保存分类列表到 SharedPreferences
  Future<void> _saveCategories(List<CategoryModel> categories) async {
    try {
      final jsonList = categories.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_categoriesKey, jsonString);
    } catch (e) {
      throw Exception('保存分类数据失败: $e');
    }
  }

  /// 清除所有分类（用于测试）
  Future<void> clearAllCategories() async {
    await _prefs.remove(_categoriesKey);
    await _prefs.remove(_initializedKey);
    await _prefs.remove(_versionKey);
  }
}
