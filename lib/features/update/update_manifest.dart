// lib/features/update/update_manifest.dart
//
// 在线更新的**纯逻辑层**（无 IO、无 Flutter 依赖），便于单测锁死三件事：
//   1) manifest JSON 的字段校验（缺字段/类型错 → 明确报错，而不是静默当成"无更新"）；
//   2) 版本号比较（1.10.0 > 1.9.0，v 前缀、两段版本 1.2 都要能处理）；
//   3) 双通道数据结构：GitHub 直连优先，jsDelivr 镜像兜底（同源内容）。

/// 更新通道。检测时按 [UpdateSource.github] → [UpdateSource.mirror] 顺序尝试。
///
/// 两条通道的**内容来源都是 GitHub 仓库**，区别只在分发路径：
/// GitHub raw 直连 / jsDelivr CDN。不存在自建服务器。
enum UpdateSource {
  /// 主通道：GitHub raw（latest.json）+ GitHub Release（APK）
  github,

  /// 镜像通道：jsDelivr 对同一仓库的 CDN 加速
  mirror;

  String get label => switch (this) {
        UpdateSource.github => 'GitHub',
        UpdateSource.mirror => 'jsDelivr',
      };
}

/// 版本清单。GitHub 与 jsDelivr 镜像用**同一份** JSON 结构，
/// 差别只在 `apkUrl` 是否需要改成本地镜像地址。
class UpdateManifest {
  const UpdateManifest({
    required this.version,
    required this.apkUrl,
    this.notes = '',
    this.fallbackApkUrl,
    this.sha256,
    this.sizeBytes,
    this.publishedAt,
  });

  /// 语义化版本，例如 `1.1.0`（不带 v 前缀；带 v 也会被归一化）。
  final String version;

  /// 主下载地址（通常指向 GitHub Release）。
  final String apkUrl;

  /// 更新说明（纯文本，按行显示）。
  final String notes;

  /// 备用下载地址（可选，同源镜像）。主地址失败时使用。
  final String? fallbackApkUrl;

  /// 小写十六进制的 sha256；缺失则不校验。
  final String? sha256;

  /// 文件字节数；缺失时按下载流统计。
  final int? sizeBytes;

  final DateTime? publishedAt;

  /// 解析并校验。任何字段不合法都抛 [UpdateManifestException]，
  /// 调用方据此切换到下一个通道，而不是把坏数据当成"已是最新"。
  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    final version = _readString(json, 'version');
    final apkUrl = _readString(json, 'apkUrl');
    final notes = json['notes'];
    final fallback = json['fallbackApkUrl'];
    final sha = json['sha256'];
    final size = json['size'];
    final published = json['publishedAt'];

    if (version.isEmpty) {
      throw const UpdateManifestException('version 为空');
    }
    if (!_looksLikeUrl(apkUrl)) {
      throw UpdateManifestException('apkUrl 不是合法 http(s) 地址：$apkUrl');
    }
    return UpdateManifest(
      version: normalizeVersion(version),
      apkUrl: apkUrl,
      notes: notes is String ? notes : '',
      fallbackApkUrl:
          fallback is String && _looksLikeUrl(fallback) ? fallback : null,
      sha256: sha is String && sha.length == 64 ? sha.toLowerCase() : null,
      sizeBytes: size is num ? size.toInt() : int.tryParse('${size ?? ''}'),
      publishedAt: published is String ? DateTime.tryParse(published) : null,
    );
  }

  /// 比 [current] 新才返回 true（同版本或更旧都算"无需更新"）。
  bool isNewerThan(String current) => compareVersions(version, current) > 0;

  /// 依次尝试的下载地址：主地址在前，兜底在后；自动去重。
  List<String> get downloadUrls {
    final urls = <String>[apkUrl];
    final f = fallbackApkUrl;
    if (f != null && f.isNotEmpty && f != apkUrl) urls.add(f);
    return urls;
  }
}

class UpdateManifestException implements Exception {
  const UpdateManifestException(this.message);
  final String message;
  @override
  String toString() => 'UpdateManifestException: $message';
}

String _readString(Map<String, dynamic> json, String key) {
  final v = json[key];
  if (v is String) return v.trim();
  if (v == null) throw UpdateManifestException('缺少字段 $key');
  throw UpdateManifestException('字段 $key 类型错误：${v.runtimeType}');
}

bool _looksLikeUrl(String url) {
  final uri = Uri.tryParse(url);
  return uri != null &&
      (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

/// 去掉 `v`/`V` 前缀与首尾空白，便于把 tag（v1.1.0）与构建版本（1.1.0）对齐。
String normalizeVersion(String raw) {
  var v = raw.trim();
  if (v.startsWith('v') || v.startsWith('V')) v = v.substring(1);
  return v;
}

/// 版本比较：返回 1 / 0 / -1。
///
/// 规则（够用即可，不追求完整 SemVer）：
///   · 按 `.` 切段，逐段比数值；
///   · 段数不同时缺位按 0 处理（1.2 == 1.2.0）；
///   · 非数字段（如 `1.2.0-beta`）取前导数字，纯文本按字典序兜底。
int compareVersions(String a, String b) {
  final pa = _segments(a);
  final pb = _segments(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : _Seg(0, '');
    final y = i < pb.length ? pb[i] : _Seg(0, '');
    if (x.number != y.number) return x.number > y.number ? 1 : -1;
    if (x.suffix != y.suffix) {
      // 同数字时：无后缀 > 有后缀（1.2.0 > 1.2.0-beta）
      if (x.suffix.isEmpty) return 1;
      if (y.suffix.isEmpty) return -1;
      return x.suffix.compareTo(y.suffix) > 0 ? 1 : -1;
    }
  }
  return 0;
}

class _Seg {
  const _Seg(this.number, this.suffix);
  final int number;
  final String suffix;
}

List<_Seg> _segments(String raw) {
  final v = normalizeVersion(raw);
  if (v.isEmpty) return const [_Seg(0, '')];
  return v.split('.').map((part) {
    final m = RegExp(r'^(\d+)(.*)$').firstMatch(part.trim());
    if (m == null) return _Seg(0, part.trim());
    return _Seg(int.parse(m.group(1)!), m.group(2) ?? '');
  }).toList();
}
