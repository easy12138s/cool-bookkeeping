import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/category_model.dart';
import '../../providers/categories_provider.dart';

/// 类别管理页面
/// 管理收入和支出类别
class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('类别管理'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '支出'),
            Tab(text: '收入'),
          ],
        ),
      ),
      body: categoriesAsync.when(
        data: (categories) => TabBarView(
          controller: _tabController,
          children: [
            // 支出类别
            _buildCategoryList(context, ref, categories, 0),
            // 收入类别
            _buildCategoryList(context, ref, categories, 1),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('加载失败: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建类别列表
  Widget _buildCategoryList(
    BuildContext context,
    WidgetRef ref,
    List<CategoryModel> categories,
    int type,
  ) {
    final filteredCategories = categories
        .where((c) => c.type == type)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (filteredCategories.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final category = filteredCategories[index];
        return _buildCategoryItem(context, ref, category);
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(int type) {
    final typeText = type == 0 ? '支出' : '收入';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无$typeText类别',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  /// 构建类别项
  Widget _buildCategoryItem(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    final color = category.type == 0
        ? AppColors.expenseColor
        : AppColors.incomeColor;

    return Dismissible(
      key: Key(category.id),
      direction: category.isPreset
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog(context, category);
      },
      onDismissed: (direction) {
        ref.read(categoriesProvider.notifier).deleteCategory(category.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('类别已删除')),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIconData(category.icon),
              color: color,
              size: 20,
            ),
          ),
          title: Text(category.name),
          subtitle: category.isPreset
              ? const Text(
                  '预设类别',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: category.isPreset
              ? null
              : IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () =>
                      _showEditCategoryDialog(context, ref, category),
                ),
          onTap: category.isPreset
              ? null
              : () => _showEditCategoryDialog(context, ref, category),
        ),
      ),
    );
  }

  /// 显示删除确认对话框
  Future<bool?> _showDeleteConfirmDialog(
    BuildContext context,
    CategoryModel category,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除类别 "${category.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示添加类别对话框
  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final type = _tabController.index;
    _showCategoryDialog(context, ref, type: type);
  }

  /// 显示编辑类别对话框
  void _showEditCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    _showCategoryDialog(
      context,
      ref,
      category: category,
      type: category.type,
    );
  }

  /// 显示类别对话框（添加/编辑）
  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref, {
    CategoryModel? category,
    required int type,
  }) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    String selectedIcon = category?.icon ?? 'category';

    // 可选图标列表
    final availableIcons = [
      'restaurant',
      'directions_car',
      'shopping_bag',
      'movie',
      'home',
      'local_hospital',
      'school',
      'work',
      'card_giftcard',
      'trending_up',
      'timer',
      'redeem',
      'shopping_cart',
      'local_grocery_store',
      'fitness_center',
      'flight',
      'hotel',
      'phone',
      'wifi',
      'pets',
      'child_care',
      'book',
      'music_note',
      'photo_camera',
      'computer',
      'phone_iphone',
      'directions_bus',
      'local_taxi',
      'local_gas_station',
      'build',
      'more_horiz',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? '编辑类别' : '添加类别'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 名称输入
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '类别名称',
                    hintText: '请输入类别名称',
                  ),
                ),
                const SizedBox(height: 16),
                // 图标选择
                const Text(
                  '选择图标',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableIcons.map((iconName) {
                    final isSelected = selectedIcon == iconName;
                    final color = type == 0
                        ? AppColors.expenseColor
                        : AppColors.incomeColor;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedIcon = iconName;
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.2)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? color : AppColors.divider,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Icon(
                          _getIconData(iconName),
                          color: isSelected ? color : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入类别名称')),
                  );
                  return;
                }

                if (isEditing) {
                  // 更新类别
                  final updatedCategory = category.copyWith(
                    name: name,
                    icon: selectedIcon,
                  );
                  await ref
                      .read(categoriesProvider.notifier)
                      .updateCategory(updatedCategory);
                } else {
                  // 添加新类别
                  final newCategory = CategoryModel(
                    id: const Uuid().v4(),
                    name: name,
                    icon: selectedIcon,
                    type: type,
                    isPreset: false,
                    isEnabled: true,
                    sortOrder: 999, // 自定义类别排在后面
                  );
                  await ref
                      .read(categoriesProvider.notifier)
                      .addCategory(newCategory);
                }

                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(isEditing ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取图标数据
  IconData _getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'shopping_bag': Icons.shopping_bag,
      'movie': Icons.movie,
      'home': Icons.home,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'more_horiz': Icons.more_horiz,
      'work': Icons.work,
      'card_giftcard': Icons.card_giftcard,
      'trending_up': Icons.trending_up,
      'timer': Icons.timer,
      'redeem': Icons.redeem,
      'category': Icons.category,
      'shopping_cart': Icons.shopping_cart,
      'local_grocery_store': Icons.local_grocery_store,
      'fitness_center': Icons.fitness_center,
      'flight': Icons.flight,
      'hotel': Icons.hotel,
      'phone': Icons.phone,
      'wifi': Icons.wifi,
      'pets': Icons.pets,
      'child_care': Icons.child_care,
      'book': Icons.book,
      'music_note': Icons.music_note,
      'photo_camera': Icons.photo_camera,
      'computer': Icons.computer,
      'phone_iphone': Icons.phone_iphone,
      'directions_bus': Icons.directions_bus,
      'local_taxi': Icons.local_taxi,
      'local_gas_station': Icons.local_gas_station,
      'build': Icons.build,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
