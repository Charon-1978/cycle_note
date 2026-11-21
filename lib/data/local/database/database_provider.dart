// lib/data/local/database/database_provider.dart
//
// 数据库的 Provider 入口。
//
// 注意：AppDatabase 构造时用的是 EncryptedDatabaseOpener（懒加载），
// 真正的文件打开发生在第一次查询，因此这里不会阻塞 App 启动。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
