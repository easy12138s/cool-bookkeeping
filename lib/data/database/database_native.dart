import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Native 平台（Android/iOS/Desktop）数据库连接
QueryExecutor createExecutor() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cool_bookkeeping.db'));
    return NativeDatabase.createInBackground(file);
  });
}
