import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/categories_table.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// 获取所有分类，按排序顺序排列
  Future<List<Category>> getAllCategories() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// 获取所有分类（Stream 形式）
  Stream<List<Category>> watchAllCategories() {
    return (select(categories)
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// 根据类型获取分类
  /// type: 0=支出, 1=收入
  Future<List<Category>> getCategoriesByType(int type) {
    return (select(categories)
          ..where((c) => c.type.equals(type))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// 根据类型获取分类（Stream 形式）
  Stream<List<Category>> watchCategoriesByType(int type) {
    return (select(categories)
          ..where((c) => c.type.equals(type))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .watch();
  }

  /// 根据 ID 获取单个分类
  Future<Category?> getCategoryById(String id) {
    return (select(categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
  }

  /// 插入分类
  Future<int> insertCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  /// 批量插入分类
  Future<void> insertAllCategories(List<CategoriesCompanion> categoriesList) async {
    await batch((batch) {
      batch.insertAll(categories, categoriesList);
    });
  }

  /// 更新分类
  Future<bool> updateCategory(CategoriesCompanion category) {
    return update(categories).replace(category);
  }

  /// 删除分类
  Future<int> deleteCategory(String id) {
    return (delete(categories)..where((c) => c.id.equals(id))).go();
  }

  /// 获取启用的分类
  Future<List<Category>> getEnabledCategories() {
    return (select(categories)
          ..where((c) => c.isEnabled.equals(true))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }

  /// 获取启用的分类（根据类型）
  Future<List<Category>> getEnabledCategoriesByType(int type) {
    return (select(categories)
          ..where((c) => c.isEnabled.equals(true) & c.type.equals(type))
          ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
        .get();
  }
}
