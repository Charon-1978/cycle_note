// lib/core/database/db_backup.dart
//
// 数据库升级前的自动备份与恢复。
//
// 为什么必须有（AGENTS.md R5 / 可行性计划书 R1）：
//   drift 的 onUpgrade 一旦写错，用户历史经期数据就没了，且无法挽回。
//   备份是唯一能兜住这个风险的手段 —— 它比任何测试都重要。
//
// 工作方式：
//   1) 开库前比较「已持久化的 schema 版本」与「目标版本」
//   2) 需要升级且库文件存在 → 复制一份带版本号的备份（含 -wal / -shm）
//   3) AppDatabase.beforeOpen 成功后调用 markUpgraded（记录版本 + 丢弃备份）
//   4) onUpgrade 抛异常 → markUpgradeFailed（保留备份，供 restoreLatest 恢复）
//   5) 每次启动清理超过 keepDays 的旧备份，但至少保留 1 份
//
// 注意：SQLCipher 加密库的备份是**密文拷贝**。恢复时密钥必须一致。
//       DbKeyStore 的密钥独立于库文件，替换库文件不影响解密，因此恢复是安全的。

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DbBackup {
  DbBackup._();

  /// 已成功打开的 schema 版本。
  static const String prefSchemaVersion = 'db_schema_version';

  /// onUpgrade 失败标记。
  static const String prefUpgradeFailed = 'db_upgrade_failed';

  static const String backupDirName = 'db_backup';

  /// 备份保留天数。
  static const int keepDays = 7;

  /// 测试用：覆盖文档目录，避免依赖 path_provider 插件。
  @visibleForTesting
  static Directory? overrideDocumentsDir;

  /// 若需要升级则备份，返回备份文件；无需升级返回 null。
  static Future<File?> beforeUpgradeIfNeeded({
    required String dbPath,
    required int targetSchemaVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 首次安装没有该键 —— 视为无需备份（尚无用户数据）
    final storedVersion = prefs.getInt(prefSchemaVersion);
    if (storedVersion == null) return null;
    if (storedVersion >= targetSchemaVersion) return null;

    final dbFile = File(dbPath);
    if (!await dbFile.exists()) return null;

    final dir = await _dir();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final backup = File(p.join(
      dir.path,
      'yueji_v${storedVersion}_to_v${targetSchemaVersion}_$stamp.sqlite',
    ));

    await dbFile.copy(backup.path);
    // WAL 模式下未落盘的数据必须一起备份，否则恢复会丢最近的记录
    await _copySibling(dbPath, '-wal', backup.path);
    await _copySibling(dbPath, '-shm', backup.path);

    await prefs.setBool(prefUpgradeFailed, false);
    return backup;
  }

  /// 迁移成功：记录版本并丢弃本次备份。
  static Future<void> markUpgraded({
    required int schemaVersion,
    File? backup,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefSchemaVersion, schemaVersion);
    await prefs.setBool(prefUpgradeFailed, false);
    await discard(backup);
  }

  /// 迁移失败：只打标记，**保留备份**。
  static Future<void> markUpgradeFailed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefUpgradeFailed, true);
  }

  /// 上一次升级是否失败（启动时可据此提示「可恢复」）。
  static Future<bool> hasUpgradeFailure() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefUpgradeFailed) ?? false;
  }

  /// 删除指定备份（连同其 -wal / -shm）。
  static Future<void> discard(File? backup) async {
    if (backup == null) return;
    try {
      if (await backup.exists()) await backup.delete();
      for (final suffix in ['-wal', '-shm']) {
        final s = File('${backup.path}$suffix');
        if (await s.exists()) await s.delete();
      }
    } catch (_) {
      // 清理失败不影响主流程
    }
  }

  /// 用最新备份恢复数据库。
  ///
  /// ⚠️ 会覆盖当前库。调用方必须先关闭 AppDatabase 并取得用户确认。
  static Future<bool> restoreLatest(String dbPath) async {
    final backups = await listBackups();
    if (backups.isEmpty) return false;

    // 先删残留 WAL/SHM，否则会和恢复出的主库不一致
    for (final suffix in ['-wal', '-shm']) {
      final s = File('$dbPath$suffix');
      if (await s.exists()) await s.delete();
    }
    await backups.first.copy(dbPath);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefUpgradeFailed, false);
    return true;
  }

  /// 备份列表，按文件名倒序（最新在前）。
  static Future<List<File>> listBackups() async {
    final dir = await _dir();
    final files = <File>[];
    await for (final e in dir.list()) {
      if (e is File && e.path.endsWith('.sqlite')) files.add(e);
    }
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// 清理过期备份，至少保留最新 1 份。返回删除数量。
  static Future<int> purgeOld({int keepDays = DbBackup.keepDays}) async {
    final deadline = DateTime.now().subtract(Duration(days: keepDays));
    final files = await listBackups();
    var removed = 0;

    for (var i = 0; i < files.length; i++) {
      if (i == 0) continue; // 永远保留最新一份
      try {
        final stat = await files[i].stat();
        if (stat.modified.isBefore(deadline)) {
          await discard(files[i]);
          removed++;
        }
      } catch (_) {
        // 单文件失败忽略
      }
    }
    return removed;
  }

  // ---------------- 内部 ----------------

  static Future<Directory> _dir() async {
    final base = overrideDocumentsDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, backupDirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<void> _copySibling(
    String dbPath,
    String suffix,
    String backupPath,
  ) async {
    final src = File('$dbPath$suffix');
    if (!await src.exists()) return;
    await src.copy('$backupPath$suffix');
  }
}
