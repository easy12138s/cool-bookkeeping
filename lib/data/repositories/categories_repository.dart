import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/daos/categories_dao.dart';
import '../models/category_model.dart';

/// 分类 Repository 层
/// 负责分类数据的业务逻辑处理和数据转换
class CategoriesRepository {
  final CategoriesDao _categoriesDao;

  CategoriesRepository(this._categoriesDao);

  /// 获取所有分类
  Future<List<CategoryModel>> getAllCategories() async {
    final categories = await _categoriesDao.getAllCategories();
    return categories.map(_toModel).toList();
  }

  /// 根据类型获取分类
  /// type: 0=支出, 1=收入
  Future<List<CategoryModel>> getCategoriesByType(int type) async {
    final categories = await _categoriesDao.getCategoriesByType(type);
    return categories.map(_toModel).toList();
  }

  /// 根据 ID 获取单个分类
  Future<CategoryModel?> getCategoryById(String id) async {
    final category = await _categoriesDao.getCategoryById(id);
    return category != null ? _toModel(category) : null;
  }

  /// 插入新分类
  Future<void> insertCategory(CategoryModel model) async {
    final companion = _toCompanion(model);
    await _categoriesDao.insertCategory(companion);
  }

  /// 更新分类
  Future<void> updateCategory(CategoryModel model) async {
    final companion = _toCompanion(model);
    await _categoriesDao.updateCategory(companion);
  }

  /// 删除分类
  /// 预设分类不能删除，会抛出异常
  Future<void> deleteCategory(String id) async {
    final category = await _categoriesDao.getCategoryById(id);

    if (category == null) {
      throw Exception('分类不存在');
    }

    if (category.isPreset) {
      throw Exception('预设分类不能删除');
    }

    await _categoriesDao.deleteCategory(id);
  }

  /// 批量插入默认分类
  /// 用于应用首次启动时初始化预设分类
  Future<void> insertDefaultCategories(List<CategoryModel> models) async {
    final companions = models.map(_toCompanion).toList();
    await _categoriesDao.insertAllCategories(companions);
  }

  /// 将数据库 Category 转换为 CategoryModel
  CategoryModel _toModel(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      icon: category.icon,
      type: category.type,
      isPreset: category.isPreset,
      isEnabled: category.isEnabled,
      sortOrder: category.sortOrder,
    );
  }

  /// 将 CategoryModel 转换为数据库 CategoriesCompanion
  CategoriesCompanion _toCompanion(CategoryModel model) {
    return CategoriesCompanion(
      id: Value(model.id),
      name: Value(model.name),
      icon: Value(model.icon),
      type: Value(model.type),
      isPreset: Value(model.isPreset),
      isEnabled: Value(model.isEnabled),
      sortOrder: Value(model.sortOrder),
    );
  }
}
