// lib/features/update/update_service.dart
//
// 在线更新的 IO 层：拉 manifest、比较版本、下载 APK、校验 sha256、交给系统安装。
//
// 通道策略（2026-11 起：完全脱钩自建服务器，只发 GitHub）：
//   1) 先请求 GitHub raw 的 latest.json；成功且版本更新 → 用 GitHub 的 apkUrl 下载；
//   2) GitHub 拉不到（超时 / 4xx / JSON 坏）→ 改请求 jsDelivr 镜像的 latest.json
//      （内容同源 GitHub，只是 CDN 不同）；
//   3) 下载阶段同样兜底：主 apkUrl 失败（任意环节，含 sha256 不符）→ 换 fallbackApkUrl。
//   两条链路的内容完全一致，版本与 sha256 由 manifest 保证。
//
// 为什么把 http.Client 注入进来：单测用 MockClient 直接造 200/500/超时，
// 不需要跑真实网络（AGENTS.md：测试不许依赖外网）。

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'update_config.dart';
import 'update_manifest.dart';

/// 检测结果。`manifest == null` 表示当前已是最新（`error == null`）
/// 或所有通道都失败（`error != null`）。
class UpdateCheckResult {
  const UpdateCheckResult({
    this.manifest,
    this.source,
    this.error,
    this.triedSources = const [],
  });

  final UpdateManifest? manifest;
  final UpdateSource? source;
  final String? error;
  final List<UpdateSource> triedSources;

  bool get hasUpdate => manifest != null;
}

/// 下载进度回调：已接收字节 / 总字节（总字节未知时为 null）。
typedef DownloadProgress = void Function(int received, int? total);

class UpdateService {
  UpdateService({
    http.Client? client,
    this.githubUrl = kUpdateUrlGitHub,
    this.mirrorUrl = kUpdateUrlMirror,
    this.currentVersion = kAppVersion,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String githubUrl;
  final String mirrorUrl;
  final String currentVersion;

  static const MethodChannel _channel = MethodChannel('com.yueji.note/update');

  /// 依次尝试 GitHub → jsDelivr 镜像。两条都失败才返回 error。
  Future<UpdateCheckResult> check() async {
    final tried = <UpdateSource>[];
    final errors = <String>[];

    for (final (source, url, timeout) in <(UpdateSource, String, Duration)>[
      (UpdateSource.github, githubUrl, kUpdateCheckTimeoutGitHub),
      (UpdateSource.mirror, mirrorUrl, kUpdateCheckTimeoutMirror),
    ]) {
      tried.add(source);
      try {
        final manifest = await _fetchManifest(url, timeout);
        if (manifest.isNewerThan(currentVersion)) {
          return UpdateCheckResult(
            manifest: manifest,
            source: source,
            triedSources: tried,
          );
        }
        // 通道可用但已是最新：不必再看镜像通道
        return UpdateCheckResult(source: source, triedSources: tried);
      } catch (e) {
        errors.add('${source.label}: ${_shortError(e)}');
      }
    }

    return UpdateCheckResult(
      error: errors.join('；'),
      triedSources: tried,
    );
  }

  Future<UpdateManifest> _fetchManifest(String url, Duration timeout) async {
    final uri = Uri.parse(url);
    final resp = await _client.get(uri).timeout(timeout);
    if (resp.statusCode != 200) {
      throw HttpException('HTTP ${resp.statusCode}', uri: uri);
    }
    final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const UpdateManifestException('manifest 不是 JSON 对象');
    }
    return UpdateManifest.fromJson(decoded);
  }

  /// 下载 APK 到缓存目录，按 [UpdateManifest.downloadUrls] 顺序尝试。
  /// 返回本地文件；全部失败时抛最后一个异常。
  Future<File> download(
    UpdateManifest manifest, {
    DownloadProgress? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final target = File('${dir.path}/yueji-${manifest.version}.apk');
    Object? lastError;

    for (final url in manifest.downloadUrls) {
      try {
        await _downloadTo(url, target, manifest, onProgress);
        return target;
      } catch (e) {
        lastError = e;
        if (await target.exists()) {
          try {
            await target.delete();
          } catch (_) {}
        }
      }
    }
    throw UpdateDownloadException(
      '下载失败：${lastError == null ? '无可用地址' : _shortError(lastError)}',
    );
  }

  Future<void> _downloadTo(
    String url,
    File target,
    UpdateManifest manifest,
    DownloadProgress? onProgress,
  ) async {
    final request = http.Request('GET', Uri.parse(url));
    final streamed =
        await _client.send(request).timeout(kUpdateDownloadTimeout);
    if (streamed.statusCode != 200) {
      throw HttpException('HTTP ${streamed.statusCode}');
    }

    final total = streamed.contentLength ??
        manifest.sizeBytes ??
        (streamed.headers['content-length'] != null
            ? int.tryParse(streamed.headers['content-length']!)
            : null);

    final sink = target.openWrite();
    var received = 0;
    final digest = _Sha256Sink();
    try {
      await for (final chunk in streamed.stream) {
        sink.add(chunk);
        digest.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    final expected = manifest.sha256;
    if (expected != null && expected.isNotEmpty) {
      final actual = digest.digest();
      if (actual != expected) {
        throw UpdateDownloadException('sha256 不匹配（期望 $expected，实际 $actual）');
      }
    }
  }

  /// 是否已允许"安装未知来源应用"。
  Future<bool> canInstall() async {
    try {
      return await _channel.invokeMethod<bool>('canInstall') ?? false;
    } on PlatformException {
      return true; // 拿不到状态时不阻断，交给系统弹窗
    }
  }

  /// 跳转到"安装未知来源应用"的设置页。
  Future<void> openInstallSettings() async {
    await _channel.invokeMethod<void>('openInstallSettings');
  }

  /// 拉起系统安装器。
  Future<void> install(File apk) async {
    await _channel.invokeMethod<void>('install', {'path': apk.path});
  }

  void dispose() => _client.close();
}

class UpdateDownloadException implements Exception {
  const UpdateDownloadException(this.message);
  final String message;
  @override
  String toString() => message;
}

String _shortError(Object e) {
  final s = e.toString();
  return s.length > 120 ? '${s.substring(0, 120)}…' : s;
}

/// 增量 sha256：下载时边收边算，避免再读一遍磁盘。
class _Sha256Sink {
  final _chunks = <int>[];

  void add(List<int> data) => _chunks.addAll(data);

  String digest() => sha256.convert(_chunks).toString();
}
