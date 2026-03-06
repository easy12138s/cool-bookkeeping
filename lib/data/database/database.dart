import 'package:drift/drift.dart';

import 'tables/records_table.dart';
import 'tables/categories_table.dart';
import 'daos/records_dao.dart';
import 'daos/categories_dao.dart';

// 条件导入：根据平台选择不同的实现
import 'database_native.dart'
    if (dart.library.html) 'database_web.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Records, Categories],
  daos: [RecordsDao, CategoriesDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(createExecutor());

  @override
  int get schemaVersion => 1;
}
