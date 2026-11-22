// test/update/update_manifest_test.dart
//
// 在线更新的纯逻辑验收：
//   · manifest 字段校验（缺字段 / 类型错 / 非 http 地址 → 明确抛错）；
//   · 版本比较（段数不同、v 前缀、预发布后缀）；
//   · 下载地址顺序（主 → 兜底，自动去重）。

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/features/update/update_manifest.dart';

void main() {
  group('compareVersions', () {
    test('常规递增', () {
      expect(compareVersions('1.1.0', '1.0.0'), 1);
      expect(compareVersions('1.0.0', '1.1.0'), -1);
      expect(compareVersions('1.0.0', '1.0.0'), 0);
    });

    test('按数值比较，不是字典序', () {
      expect(compareVersions('1.10.0', '1.9.0'), 1);
      expect(compareVersions('2.0.0', '10.0.0'), -1);
    });

    test('段数不同按 0 补齐', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2.1', '1.2'), 1);
    });

    test('容忍 v 前缀与空白', () {
      expect(compareVersions('v1.1.0', '1.0.0'), 1);
      expect(normalizeVersion('  V1.2.3 '), '1.2.3');
    });

    test('预发布后缀：正式版高于同号预发布版', () {
      expect(compareVersions('1.2.0', '1.2.0-beta'), 1);
      expect(compareVersions('1.2.0-beta', '1.2.0'), -1);
    });

    test('isNewerThan 只认"更新"', () {
      const m = UpdateManifest(version: '1.1.0', apkUrl: 'https://a/b.apk');
      expect(m.isNewerThan('1.0.0'), isTrue);
      expect(m.isNewerThan('1.1.0'), isFalse);
      expect(m.isNewerThan('1.2.0'), isFalse);
    });
  });

  group('fromJson 校验', () {
    Map<String, dynamic> base() => <String, dynamic>{
          'version': '1.2.0',
          'apkUrl': 'https://github.com/o/r/releases/download/v1.2.0/a.apk',
          'notes': '修复补记日期限制',
          'fallbackApkUrl': 'https://nas.example.com/nashub/yueji/a.apk',
          'sha256': 'a' * 64,
          'size': 31707405,
          'publishedAt': '2026-11-23T10:00:00Z',
        };

    test('完整字段可解析', () {
      final m = UpdateManifest.fromJson(base());
      expect(m.version, '1.2.0');
      expect(m.notes, '修复补记日期限制');
      expect(m.fallbackApkUrl, contains('nashub'));
      expect(m.sha256, 'a' * 64);
      expect(m.sizeBytes, 31707405);
      expect(m.publishedAt, isNotNull);
    });

    test('缺 version / apkUrl → 抛错（而不是当成"无更新"）', () {
      final noVersion = base()..remove('version');
      expect(() => UpdateManifest.fromJson(noVersion),
          throwsA(isA<UpdateManifestException>()));

      final noUrl = base()..remove('apkUrl');
      expect(() => UpdateManifest.fromJson(noUrl),
          throwsA(isA<UpdateManifestException>()));
    });

    test('apkUrl 不是 http(s) → 抛错', () {
      final bad = base()..['apkUrl'] = 'ftp://x/y.apk';
      expect(() => UpdateManifest.fromJson(bad),
          throwsA(isA<UpdateManifestException>()));
    });

    test('可选字段非法时被忽略而不是整条失败', () {
      final m = UpdateManifest.fromJson(base()
        ..['fallbackApkUrl'] = 'not-a-url'
        ..['sha256'] = 'short'
        ..['size'] = 'abc');
      expect(m.fallbackApkUrl, isNull);
      expect(m.sha256, isNull);
      expect(m.sizeBytes, isNull);
    });

    test('下载地址顺序：主地址在前，兜底在后且去重', () {
      final m = UpdateManifest.fromJson(base());
      expect(m.downloadUrls, hasLength(2));
      expect(m.downloadUrls.first, base()['apkUrl']);

      final same = UpdateManifest(
        version: '1.2.0',
        apkUrl: 'https://a/b.apk',
        fallbackApkUrl: 'https://a/b.apk',
      );
      expect(same.downloadUrls, hasLength(1));
    });
  });
}
