/// 预设类别数据定义
/// 
/// 定义应用默认的支出和收入类别，用于首次启动时初始化数据库
/// 
/// 类别类型：0 = 支出，1 = 收入
class DefaultCategories {
  DefaultCategories._();

  /// 支出类别列表
  ///
  /// 每个类别包含：
  /// - id: 唯一标识符
  /// - name: 类别名称
  /// - icon: Material Icons 图标名称
  /// - type: 类别类型 (0 = 支出)
  /// - isPreset: 是否预设类别
  /// - isEnabled: 是否启用
  /// - sortOrder: 排序顺序
  static const List<Map<String, dynamic>> expenseCategories = [
    {
      'id': 'expense_food',
      'name': '餐饮',
      'icon': 'restaurant',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 0,
    },
    {
      'id': 'expense_transport',
      'name': '交通',
      'icon': 'directions_car',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 1,
    },
    {
      'id': 'expense_shopping',
      'name': '购物',
      'icon': 'shopping_bag',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 2,
    },
    {
      'id': 'expense_entertainment',
      'name': '娱乐',
      'icon': 'movie',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 3,
    },
    {
      'id': 'expense_housing',
      'name': '居住',
      'icon': 'home',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 4,
    },
    {
      'id': 'expense_medical',
      'name': '医疗',
      'icon': 'local_hospital',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 5,
    },
    {
      'id': 'expense_education',
      'name': '教育',
      'icon': 'school',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 6,
    },
    {
      'id': 'expense_daily',
      'name': '日用',
      'icon': 'cleaning_services',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 7,
    },
    {
      'id': 'expense_clothing',
      'name': '服饰',
      'icon': 'checkroom',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 8,
    },
    {
      'id': 'expense_beauty',
      'name': '美妆',
      'icon': 'face',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 9,
    },
    {
      'id': 'expense_sports',
      'name': '运动',
      'icon': 'fitness_center',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 10,
    },
    {
      'id': 'expense_pet',
      'name': '宠物',
      'icon': 'pets',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 11,
    },
    {
      'id': 'expense_social',
      'name': '社交',
      'icon': 'group',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 12,
    },
    {
      'id': 'expense_travel',
      'name': '旅行',
      'icon': 'flight',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 13,
    },
    {
      'id': 'expense_digital',
      'name': '数码',
      'icon': 'devices',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 14,
    },
    {
      'id': 'expense_other',
      'name': '其他',
      'icon': 'more_horiz',
      'type': 0,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 15,
    },
  ];

  /// 收入类别列表
  ///
  /// 每个类别包含：
  /// - id: 唯一标识符
  /// - name: 类别名称
  /// - icon: Material Icons 图标名称
  /// - type: 类别类型 (1 = 收入)
  /// - isPreset: 是否预设类别
  /// - isEnabled: 是否启用
  /// - sortOrder: 排序顺序
  static const List<Map<String, dynamic>> incomeCategories = [
    {
      'id': 'income_salary',
      'name': '工资',
      'icon': 'work',
      'type': 1,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 0,
    },
    {
      'id': 'income_bonus',
      'name': '奖金',
      'icon': 'card_giftcard',
      'type': 1,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 1,
    },
    {
      'id': 'income_investment',
      'name': '投资',
      'icon': 'trending_up',
      'type': 1,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 2,
    },
    {
      'id': 'income_parttime',
      'name': '兼职',
      'icon': 'timer',
      'type': 1,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 3,
    },
    {
      'id': 'income_gift',
      'name': '礼金',
      'icon': 'redeem',
      'type': 1,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 4,
    },
    {
      'id': 'income_allowance',
      'name': '补贴',
      'icon': 'payments',
      'type': 1,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 5,
    },
    {
      'id': 'income_refund',
      'name': '退款',
      'icon': 'replay',
      'type': 1,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 6,
    },
    {
      'id': 'income_other',
      'name': '其他',
      'icon': 'more_horiz',
      'type': 1,
      'isPreset': true,
      'isEnabled': true,
      'sortOrder': 7,
    },
  ];

  /// 获取所有默认类别
  static List<Map<String, dynamic>> get allCategories => [
        ...expenseCategories,
        ...incomeCategories,
      ];
}
