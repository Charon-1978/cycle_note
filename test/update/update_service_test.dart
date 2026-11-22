// test/update/update_service_test.dart
//
// 双通道策略的验收（用 MockClient，不碰真实网络）：
//   1) GitHub 可用 → 用 GitHub，不再请求 NASHub；
//   2) GitHub 500 / 超时 / JSON 坏 → 自动切 NASHub；
//   3) 两条都失败 → error 里能看到两个通道的原因；
//   4) 通道可用但版本不新 → hasUpdate == false（不再打兜底通道）；
//   5) 下载：主地址失败 → 换 fallback；sha256 不符 → 也换 fallback。

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:cycle_note/features/update/update_manifest.dart';
import 'package:cycle_note/features/update/update_service.dart';

const _githubManifest = 'https://raw.githubusercontent.com/o/r/main/update/latest.json';
const _nasManifest = 'https://nas.example.com/nashub/yueji/latest.json';

String _manifestJson({
  String version = '1.2.0',
  String apkUrl = 'https://github.com/o/r/releases/download/v1.2.0/a.apk',
  String? fallback,
  String? sha256,
}) =>
    jsonEncode(<String, dynamic>{
      'version': version,
      'apkUrl': apkUrl,
      if (fallback != null) 'fallbackApkUrl': fallback,
      if (sha256 != null) 'sha256': sha256,
      'notes': 'test',
    });

/// 假的 path_provider：把临时目录指到测试可写的 build 目录下。
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.dir);
  final String dir;

  @override
  Future<String?> getTemporaryPath() async => dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  final requests = <String>[];

  setUp(() async {
    requests.clear();
    tmp = await Directory.systemTemp.createTemp('yueji_update_test');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  UpdateService serviceWith(MockClient client) => UpdateService(
        client: client,
        githubUrl: _githubManifest,
        nasUrl: _nasManifest,
        currentVersion: '1.0.0',
      );

  group('检测', () {
    test('GitHub 可用 → 用 GitHub，且不请求 NASHub', () async {
      final client = MockClient((req) async {
        requests.add(req.url.toString());
        return http.Response(_manifestJson(), 200);
      });

      final r = await serviceWith(client).check();
      expect(r.hasUpdate, isTrue);
      expect(r.source, UpdateSource.github);
      expect(r.manifest!.version, '1.2.0');
      expect(requests, [_githubManifest]);
    });

    test('GitHub 500 → 自动切 NASHub', () async {
      final client = MockClient((req) async {
        requests.add(req.url.toString());
        if (req.url.toString() == _githubManifest) {
          return http.Response('boom', 500);
        }
        return http.Response(
          _manifestJson(apkUrl: 'https://nas.example.com/nashub/yueji/a.apk'),
          200,
        );
      });

      final r = await serviceWith(client).check();
      expect(r.hasUpdate, isTrue);
      expect(r.source, UpdateSource.nas);
      expect(r.triedSources, [UpdateSource.github, UpdateSource.nas]);
      expect(requests, [_githubManifest, _nasManifest]);
    });

    test('GitHub 返回坏 JSON → 切 NASHub', () async {
      final client = MockClient((req) async {
        if (req.url.toString() == _githubManifest) {
          return http.Response('{not json', 200);
        }
        return http.Response(_manifestJson(), 200);
      });

      final r = await serviceWith(client).check();
      expect(r.source, UpdateSource.nas);
      expect(r.hasUpdate, isTrue);
    });

    test('两条都失败 → error 里包含两个通道的原因', () async {
      final client = MockClient((req) async {
        if (req.url.toString() == _githubManifest) {
          throw SocketException('no route');
        }
        return http.Response('nope', 503);
      });

      final r = await serviceWith(client).check();
      expect(r.hasUpdate, isFalse);
      expect(r.error, contains('GitHub'));
      expect(r.error, contains('NASHub'));
    });

    test('通道可用但版本相同 → 无更新，且不再请求兜底通道', () async {
      final client = MockClient((req) async {
        requests.add(req.url.toString());
        return http.Response(_manifestJson(version: '1.0.0'), 200);
      });

      final r = await serviceWith(client).check();
      expect(r.hasUpdate, isFalse);
      expect(r.error, isNull);
      expect(requests, [_githubManifest]);
    });
  });

  group('下载', () {
    UpdateManifest manifestWith({String? fallback, String? sha256}) =>
        UpdateManifest(
          version: '1.2.0',
          apkUrl: 'https://github.com/o/r/a.apk',
          fallbackApkUrl: fallback,
          sha256: sha256,
          sizeBytes: 5,
        );

    test('主地址 200 → 落盘成功', () async {
      final client = MockClient((req) async {
        requests.add(req.url.toString());
        return http.Response.bytes(utf8.encode('APKDATA'), 200);
      });

      final file = await serviceWith(client).download(manifestWith());
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), 'APKDATA');
      expect(requests, ['https://github.com/o/r/a.apk']);
    });

    test('主地址 404 → 换 fallback', () async {
      final client = MockClient((req) async {
        requests.add(req.url.toString());
        if (req.url.toString().contains('github.com')) {
          return http.Response('missing', 404);
        }
        return http.Response.bytes(utf8.encode('NASDATA'), 200);
      });

      final file = await serviceWith(client).download(
        manifestWith(fallback: 'https://nas.example.com/nashub/a.apk'),
      );
      expect(await file.readAsString(), 'NASDATA');
      expect(requests, hasLength(2));
    });

    test('主地址内容 sha256 不符 → 丢弃并换 fallback（兜底内容正确）', () async {
      final good = sha256.convert(utf8.encode('NASDATA')).toString();
      final client = MockClient((req) async {
        requests.add(req.url.toString());
        if (req.url.toString().contains('github.com')) {
          return http.Response.bytes(utf8.encode('GITHUB'), 200);
        }
        return http.Response.bytes(utf8.encode('NASDATA'), 200);
      });

      final file = await serviceWith(client).download(
        manifestWith(
          fallback: 'https://nas.example.com/nashub/a.apk',
          sha256: good,
        ),
      );
      expect(await file.readAsString(), 'NASDATA');
      expect(requests, hasLength(2), reason: '主地址 hash 不符后应换兜底');
    });
    test('两个地址都拿不到 → 抛 UpdateDownloadException', () async {
      final client = MockClient((req) async => http.Response('x', 500));

      expect(
        () => serviceWith(client).download(
          manifestWith(fallback: 'https://nas.example.com/nashub/a.apk'),
        ),
        throwsA(isA<UpdateDownloadException>()),
      );
    });
  });
}
