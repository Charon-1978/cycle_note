// lib/core/database/encrypted_database_opener.dart
//
// SQLCipher 加密开库器 + 升级前自动备份。
//
// AppDatabase 只需：
//   super(EncryptedDatabaseOpener.open(schemaVersion: kSchemaVersion))
//
// 加密是怎么生效的（2026-11 修正，历史教训写在这里）：
//   package:sqlite3 3.x 已经没有 `open.overrideFor(...)` 了，改为在**构建期**
//   由 native asset hook 决定链哪个原生库。默认 `source: sqlite3` 下载的是
//   普通 SQLite，此时 `PRAGMA key` 会被当成未知 pragma **静默忽略** ——
//   跑得通、测试全绿、库里却是明文。
//
//   所以真正的开关在 pubspec.yaml：
//     hooks:
//       user_defines:
//         sqlite3:
//           source: sqlcipher
//
//   并且这里加了运行时硬校验：`PRAGMA cipher_version` 在普通 sqlite 上返回
//   空结果集，取不到就直接抛 DatabaseEncryptionUnavailable，宁可开不了库，
//   也不静默写明文。test/database/sqlcipher_available_test.dart 在 CI 里锁死
//   这一条。

import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../security/db_key_store.dart';
import 'db_backup.dart';

/// 原生库不是 SQLCipher 版（或被同名普通 sqlite 抢先加载）。
///
/// 出现这个异常说明**构建配置错了**，不是数据问题：
/// 检查 pubspec.yaml 的 hooks.user_defines.sqlite3.source == sqlcipher，
/// 并确认没有其它依赖塞进来的 libsqlite3.so / libsqlcipher.so。
class DatabaseEncryptionUnavailable implements Exception {
  const DatabaseEncryptionUnavailable([this.detail]);

  final String? detail;

  @override
  String toString() => 'DatabaseEncryptionUnavailable: 当前原生库不支持 SQLCipher，'
      '拒绝以明文方式打开数据库'
      '${detail == null ? '' : '（$detail）'}';
}

class EncryptedDatabaseOpener {
  EncryptedDatabaseOpener._();

  /// 默认库文件名。改名等于换库（旧数据不可见），**不要轻易改**。
  static const String defaultFileName = 'yueji.sqlite';

  /// 本次启动若发生了升级，这里持有升级前的备份，供 AppDatabase 收尾。
  static File? _pendingBackup;
  static File? get pendingBackup => _pendingBackup;

  /// 最近一次成功开库时读到的 SQLCipher 版本号（诊断页 / 日志用）。
  static String? lastCipherVersion;

  /// 校验当前原生库确实是 SQLCipher。
  ///
  /// 普通 SQLite 上 `PRAGMA cipher_version` 返回空结果集（不报错），
  /// 这是唯一可靠的判别方式。
  static String? readCipherVersion(sqlite3.Database raw) {
    final rows = raw.select('PRAGMA cipher_version');
    if (rows.isEmpty) return null;
    final value = rows.first.values.first;
    return value?.toString();
  }

  static QueryExecutor open({
    String fileName = defaultFileName,
    bool encrypted = true,
    bool logStatements = false,
    int schemaVersion = 1,
  }) {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, fileName));

      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      // 升级前备份：防「onUpgrade 写错导致历史数据全丢」的唯一保险
      _pendingBackup = await DbBackup.beforeUpgradeIfNeeded(
        dbPath: file.path,
        targetSchemaVersion: schemaVersion,
      );

      // 清理过期备份，不阻塞开库
      unawaited(DbBackup.purgeOld());

      String? key;
      if (encrypted) {
        key = await DbKeyStore.getOrCreate();
      }

      // 为什么不用 NativeDatabase.createInBackground：
      //   模拟器真机实测（Android 16 / x86_64）发现，后台 isolate 打开
      //   SQLCipher 时 `package:jni` 找不到 `android.content.Context`
      //   （ClassNotFoundException），库因此完全打不开、databases 目录为空。
      //   同 isolate 打开则一切正常 —— 后台 isolate 缺少 JNI 的 ClassLoader
      //   上下文，这是 jni 包在非主 isolate 的已知限制。
      //   代价：DB 操作回到 UI isolate。查询量级很小（单用户本地库），
      //   实测无感知卡顿；换来的是"库能打开"这一硬前提。
      return NativeDatabase(
        file,
        logStatements: logStatements,
        setup: (raw) {
          if (key != null) {
            // key 为 64 位 hex（仅 0-9a-f），不含引号，可安全内联。
            // 注意：必须是对该连接执行的**第一条**语句。
            raw.execute("PRAGMA key = '$key'");

            // 硬校验：取不到 cipher_version 说明原生库是普通 sqlite，
            // 上面那行 PRAGMA key 已经被静默丢弃了。
            final version = readCipherVersion(raw);
            if (version == null) {
              throw const DatabaseEncryptionUnavailable(
                'PRAGMA cipher_version 为空，pubspec.yaml 的 '
                'hooks.user_defines.sqlite3.source 是否已设为 sqlcipher？',
              );
            }
            lastCipherVersion = version;

            raw.execute('PRAGMA cipher_memory_security = ON');
          }
          raw.execute('PRAGMA foreign_keys = ON');
        },
      );
    });
  }

  /// 数据库文件路径（备份 / 导出 / 排查用）。
  static Future<String> resolvePath({
    String fileName = defaultFileName,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, fileName);
  }
}
