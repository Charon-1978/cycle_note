// lib/core/security/db_key_store.dart
//
// 数据库加密密钥的生成与保管。
//
// 安全要求（AGENTS.md §9 数据安全红线 / R7）：
//   · 密钥只存在 flutter_secure_storage（Android Keystore 加持）
//   · 禁止写入 shared_preferences、禁止打印、禁止出现在任何日志
//   · 采用 hex 编码（64 字符，仅 0-9a-f），避免 SQLCipher 的 PRAGMA 语句
//     因引号/斜杠转义出问题——base64 的 + / = 在拼接 SQL 时是隐患
//
// 版本注意：
//   本文件按 flutter_secure_storage 9.x 编写（含 encryptedSharedPreferences）。
//   若你的项目已是 10.x，该参数被移除（底层改用 DataStore），
//   请改为 `const AndroidOptions()`，其余逻辑不变。

import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DbKeyStore {
  DbKeyStore._();

  /// 存储键名。改名会导致旧密钥读不到 → 旧库永久打不开，**切勿修改**。
  static const String storageKey = 'db_encryption_key';

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// 进程内缓存，避免每次打开数据库都走一次 KeyStore（较慢）。
  static String? _cached;

  /// 取已有密钥；不存在则生成并持久化。
  ///
  /// 返回 64 位小写 hex 字符串，可直接用于 `PRAGMA key = '<key>'`。
  static Future<String> getOrCreate() async {
    final cached = _cached;
    if (cached != null) return cached;

    final existing = await _storage.read(key: storageKey);
    if (existing != null && _isValid(existing)) {
      _cached = existing;
      return existing;
    }

    final generated = _generateHex(32); // 32 字节 = 256 bit
    await _storage.write(key: storageKey, value: generated);
    _cached = generated;
    return generated;
  }

  /// 是否已存在密钥（用于判断是首次创建库还是打开已有库）。
  static Future<bool> exists() async {
    if (_cached != null) return true;
    final v = await _storage.read(key: storageKey);
    return v != null && _isValid(v);
  }

  /// 仅用于测试与「清空数据」流程。
  ///
  /// ⚠️ 调用后旧数据库将**永久无法解密**，必须同时删除库文件，
  /// 否则 App 启动会直接报错。
  static Future<void> destroy() async {
    await _storage.delete(key: storageKey);
    _cached = null;
  }

  /// 32 字节 → 64 位 hex。
  static String _generateHex(int byteLength) {
    final rnd = Random.secure();
    final buf = StringBuffer();
    for (var i = 0; i < byteLength; i++) {
      buf.write(rnd.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buf.toString();
  }

  /// 校验：64 位且全为 hex。
  static bool _isValid(String v) {
    if (v.length != 64) return false;
    return RegExp(r'^[0-9a-f]{64}$').hasMatch(v);
  }
}
