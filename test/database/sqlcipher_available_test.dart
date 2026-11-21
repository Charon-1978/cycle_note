// test/database/sqlcipher_available_test.dart
//
// 这条测试是「加密是否真的生效」的**唯一自动化护栏**。
//
// 背景：package:sqlite3 3.x 起原生库由构建期 hook 选定，默认是普通 SQLite。
// 普通 SQLite 会把 `PRAGMA key` 当成未知 pragma 静默忽略 —— 数据库读写成
// 功、所有测试全绿、数据却是明文。`PRAGMA cipher_version` 在普通 SQLite 上
// 返回**空结果集**（不抛异常），因此它是唯一可靠的判别方式。
//
// 若这条测试失败：检查 pubspec.yaml 里
//   hooks:
//     user_defines:
//       sqlite3:
//         source: sqlcipher
// 并确认依赖树里没有 sqlcipher_flutter_libs / sqlite3_flutter_libs
// 这类会塞进同名 .so 的包。

import 'dart:io';

import 'package:cycle_note/core/database/encrypted_database_opener.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// 64 位 hex，与 DbKeyStore 产出的格式一致（不含引号，可安全内联）。
const _rightKey = '0123456789abcdef0123456789abcdef'
    '0123456789abcdef0123456789abcdef';

const _wrongKey = 'fedcba9876543210fedcba9876543210'
    'fedcba9876543210fedcba9876543210';

void main() {
  group('SQLCipher 原生库', () {
    test('cipher_version 非空（普通 sqlite 会返回空集）', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      expect(
        EncryptedDatabaseOpener.readCipherVersion(db),
        isNotNull,
        reason: '当前加载的是普通 SQLite，PRAGMA key 会被静默忽略，'
            '数据库将以明文写入。请把 sqlite3 hook 的 source 改为 sqlcipher。',
      );
    });

    test('PRAGMA key 之后仍能正常建表读写', () {
      final db = sqlite3.openInMemory();
      addTearDown(db.close);

      db.execute("PRAGMA key = '$_rightKey'");
      expect(EncryptedDatabaseOpener.readCipherVersion(db), isNotNull);

      db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
      db.execute("INSERT INTO t (v) VALUES ('经期记录')");
      expect(db.select('SELECT v FROM t').first['v'], '经期记录');
    });

    test('用错 key 打不开已加密的库（证明 key 真的参与了加密）', () {
      final dir = Directory.systemTemp.createTempSync('yueji_cipher_');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final path = '${dir.path}/cipher_probe.sqlite';

      final writer = sqlite3.open(path);
      writer.execute("PRAGMA key = '$_rightKey'");
      writer.execute('CREATE TABLE secret (v TEXT)');
      writer.execute("INSERT INTO secret (v) VALUES ('能看到')");
      writer.close();

      // 文件头不应是明文 SQLite 的 "SQLite format 3\0"
      final head = File(path).readAsBytesSync().take(16).toList();
      expect(
        String.fromCharCodes(head.where((b) => b >= 32 && b < 127)),
        isNot('SQLite format 3'),
        reason: '库文件头是明文 SQLite 魔数，说明根本没有加密',
      );

      final reader = sqlite3.open(path);
      addTearDown(reader.close);
      reader.execute("PRAGMA key = '$_wrongKey'");

      // 错 key 下读表必须失败（"file is not a database" 或 "no such table"）
      expect(
        () => reader.select('SELECT v FROM secret'),
        throwsA(isA<SqliteException>()),
      );
    });
  });
}
