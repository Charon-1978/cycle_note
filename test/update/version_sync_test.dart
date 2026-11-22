// test/update/version_sync_test.dart
//
// 版本号只有一个"真源"：pubspec.yaml 的 `version:`。
// 如果 kAppVersion 忘了改，App 会一直以为自己是旧版本（或永远提示有更新），
// 而且这种 bug 在界面上完全看不出来。所以用一条测试把它钉住。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/features/update/update_config.dart';

void main() {
  test('kAppVersion 与 pubspec.yaml 的版本一致', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*([0-9A-Za-z.\-+]+)', multiLine: true)
            .firstMatch(pubspec);
    expect(match, isNotNull, reason: 'pubspec.yaml 里必须有 version:');

    // pubspec 形如 1.0.0+1，取 + 之前的版本号
    final pubspecVersion = match!.group(1)!.split('+').first;
    expect(
      kAppVersion,
      pubspecVersion,
      reason: '改了 pubspec 的 version 就要同步 update_config.dart 的 kAppVersion',
    );
  });
}
