import 'package:drift/drift.dart';
import 'package:drift/web.dart';

/// Web 平台数据库连接
/// 使用 drift 的 Web 支持（sql.js + IndexedDB 持久化）
QueryExecutor createExecutor() {
  // 使用 WebDatabase 配合 sql.js 和 IndexedDB 实现持久化
  // ignore: deprecated_member_use
  return WebDatabase.withStorage(
    // ignore: experimental_member_use
    DriftWebStorage.indexedDb(
      'cool_bookkeeping_db',
      migrateFromLocalStorage: false,
    ),
  );
}
