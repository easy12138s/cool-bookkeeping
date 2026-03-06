import 'package:drift/drift.dart';

/// 平台特定的数据库连接创建函数
/// 在 native 和 web 平台有不同的实现
QueryExecutor createExecutor() {
  throw UnimplementedError('This platform is not supported');
}
