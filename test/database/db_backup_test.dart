// test/database/db_backup_test.dart
//
// 覆盖 P0-3 的核心风险点：
//   1) 首次安装不应生成备份（没有数据可丢）
//   2) 需要升级时必须生成备份，且内容与原件一致
//   3) 升级成功后备份被删除、版本号被记录
//   4) restoreLatest 能把备份写回库路径
//   5) purgeOld 永远保留最新一份
//
// 运行：flutter test test/database/db_backup_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/core/database/db_backup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late String dbPath;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tmp = await Directory.systemTemp.createTemp('yueji_backup_test_');
    DbBackup.overrideDocumentsDir = tmp;
    dbPath = p.join(tmp.path, 'yueji.sqlite');
  });

  tearDown(() async {
    DbBackup.overrideDocumentsDir = null;
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> writeDb(List<int> bytes) async {
    await File(dbPath).writeAsBytes(bytes, flush: true);
  }

  group('beforeUpgradeIfNeeded', () {
    test('首次安装（无版本记录）不备份', () async {
      await writeDb([1, 2, 3]);
      final b = await DbBackup.beforeUpgradeIfNeeded(
        dbPath: dbPath,
        targetSchemaVersion: 2,
      );
      expect(b, isNull);
    });

    test('库文件不存在时不备份', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{DbBackup.prefSchemaVersion: 1},
      );
      final b = await DbBackup.beforeUpgradeIfNeeded(
        dbPath: dbPath,
        targetSchemaVersion: 2,
      );
      expect(b, isNull);
    });

    test('版本落后且库存在 → 生成备份，字节一致', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{DbBackup.prefSchemaVersion: 1},
      );
      final original = List<int>.generate(64, (i) => i);
      await writeDb(original);

      final backup = await DbBackup.beforeUpgradeIfNeeded(
        dbPath: dbPath,
        targetSchemaVersion: 2,
      );

      expect(backup, isNotNull);
      expect(await backup!.exists(), isTrue);
      expect(await backup.readAsBytes(), original);
      // 文件名应包含版本信息，便于排查
      expect(p.basename(backup.path), contains('v1_to_v2'));
    });

    test('版本已是最新 → 不备份', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{DbBackup.prefSchemaVersion: 2},
      );
      await writeDb([9]);
      final b = await DbBackup.beforeUpgradeIfNeeded(
        dbPath: dbPath,
        targetSchemaVersion: 2,
      );
      expect(b, isNull);
    });

    test('-wal 与 -shm 一并备份', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{DbBackup.prefSchemaVersion: 1},
      );
      await writeDb([1]);
      await File('$dbPath-wal').writeAsBytes([7, 7]);
      await File('$dbPath-shm').writeAsBytes([8, 8]);

      final backup = await DbBackup.beforeUpgradeIfNeeded(
        dbPath: dbPath,
        targetSchemaVersion: 2,
      );

      expect(File('${backup!.path}-wal').existsSync(), isTrue);
      expect(File('${backup.path}-shm').existsSync(), isTrue);
    });
  });

  group('markUpgraded / markUpgradeFailed', () {
    test('成功后写入版本并删除备份', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{DbBackup.prefSchemaVersion: 1},
      );
      await writeDb([1, 2]);
      final backup = await DbBackup.beforeUpgradeIfNeeded(
        dbPath: dbPath,
        targetSchemaVersion: 2,
      );

      await DbBackup.markUpgraded(schemaVersion: 2, backup: backup);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(DbBackup.prefSchemaVersion), 2);
      expect(prefs.getBool(DbBackup.prefUpgradeFailed), isFalse);
      expect(await backup!.exists(), isFalse);
    });

    test('失败时保留备份并打标记', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{DbBackup.prefSchemaVersion: 1},
      );
      await writeDb([1, 2]);
      final backup = await DbBackup.beforeUpgradeIfNeeded(
        dbPath: dbPath,
        targetSchemaVersion: 2,
      );

      await DbBackup.markUpgradeFailed();

      expect(await DbBackup.hasUpgradeFailure(), isTrue);
      expect(await backup!.exists(), isTrue); // 备份必须还在
    });
  });

  group('restoreLatest', () {
    test('把最新备份写回库路径，并清掉残留 wal/shm', () async {
      SharedPreferences.setMockInitialValues(
        <String, Object>{DbBackup.prefSchemaVersion: 1},
      );
      final original = [10, 20, 30, 40];
      await writeDb(original);
      await DbBackup.beforeUpgradeIfNeeded(
        dbPath: dbPath,
        targetSchemaVersion: 2,
      );

      // 模拟升级把库写坏
      await writeDb([0, 0]);
      await File('$dbPath-wal').writeAsBytes([99]);

      final ok = await DbBackup.restoreLatest(dbPath);

      expect(ok, isTrue);
      expect(await File(dbPath).readAsBytes(), original);
      expect(File('$dbPath-wal').existsSync(), isFalse);
    });

    test('没有任何备份时返回 false', () async {
      final ok = await DbBackup.restoreLatest(dbPath);
      expect(ok, isFalse);
    });
  });

  group('listBackups / purgeOld', () {
    test('列表按时间倒序，purgeOld 保留最新一份', () async {
      // 直接造三个备份文件，避免依赖系统时间精度
      final dir = Directory(p.join(tmp.path, DbBackup.backupDirName));
      await dir.create(recursive: true);
      for (final name in ['a.sqlite', 'b.sqlite', 'c.sqlite']) {
        await File(p.join(dir.path, name)).writeAsBytes([1]);
      }

      final list = await DbBackup.listBackups();
      expect(list.length, 3);
      expect(list.first.path.compareTo(list.last.path) >= 0, isTrue);

      // keepDays = 0 → 除最新外全部过期
      final removed = await DbBackup.purgeOld(keepDays: 0);
      expect(removed, 2);
      expect((await DbBackup.listBackups()).length, 1);
    });
  });
}
