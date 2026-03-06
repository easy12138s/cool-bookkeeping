import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/category_model.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/web_categories_repository.dart';
import 'providers.dart';

/// Categories Notifier 状态类型
typedef CategoriesState = AsyncValue<List<CategoryModel>>;

/// Categories Notifier
/// 管理分类列表的状态和业务逻辑
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final dynamic _repository;

  CategoriesNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  /// 加载所有分类
  /// 从 Repository 获取数据并更新状态
  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final List<CategoryModel> categories;
      if (kIsWeb) {
        categories = await (_repository as WebCategoriesRepository).getAllCategories();
      } else {
        categories = await (_repository as CategoriesRepository).getAllCategories();
      }
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 添加新分类
  /// [category] 要添加的分类模型
  Future<void> addCategory(CategoryModel category) async {
    try {
      if (kIsWeb) {
        await (_repository as WebCategoriesRepository).insertCategory(category);
      } else {
        await (_repository as CategoriesRepository).insertCategory(category);
      }
      await loadCategories();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 更新分类
  /// [category] 要更新的分类模型
  Future<void> updateCategory(CategoryModel category) async {
    try {
      if (kIsWeb) {
        await (_repository as WebCategoriesRepository).updateCategory(category);
      } else {
        await (_repository as CategoriesRepository).updateCategory(category);
      }
      await loadCategories();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 删除分类
  /// [id] 要删除的分类 ID
  /// 注意：预设分类不能删除
  Future<void> deleteCategory(String id) async {
    try {
      if (kIsWeb) {
        await (_repository as WebCategoriesRepository).deleteCategory(id);
      } else {
        await (_repository as CategoriesRepository).deleteCategory(id);
      }
      await loadCategories();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 根据类型获取分类
  Future<List<CategoryModel>> getCategoriesByType(int type) async {
    try {
      if (kIsWeb) {
        return await (_repository as WebCategoriesRepository).getCategoriesByType(type);
      } else {
        return await (_repository as CategoriesRepository).getCategoriesByType(type);
      }
    } catch (error) {
      return [];
    }
  }
}

/// Categories Provider
/// 提供 CategoriesNotifier 实例
final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>(
  (ref) {
    final repository = ref.watch(categoriesRepositoryProvider);
    return CategoriesNotifier(repository);
  },
);
