// lib/features/update/update_config.dart
//
// 更新相关的**全部可配置项**集中在这里，替换仓库地址时只改这一个文件。
//
// 三条通道：
//   · GitHub  —— 主通道，manifest 与 APK 都放 GitHub（Release + raw）
//   · NASHub  —— 兜底通道，自建 NAS 上的静态目录，结构见 docs/在线更新与发布.md
//   · 构建期覆盖 —— 用 --dart-define 覆盖任意一项，不改代码即可切换测试环境
//
// 隐私说明：从 v1.1 起 App 申请 INTERNET 权限，但**只在用户点「检查更新」时**
// 才发起请求；没有任何埋点、日志上报、账号体系。

/// 当前版本。必须与 pubspec.yaml 的 `version:` 前段一致，
/// 由 test/update/version_sync_test.dart 在 CI 里强制校验。
const String kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.1.0',
);

/// GitHub 通道的 manifest（raw 文件，CDN 快、无需 API token）。
///
/// 例：`https://raw.githubusercontent.com/Charon-1978/cycle_note/main/update/latest.json`
const String kUpdateUrlGitHub = String.fromEnvironment(
  'UPDATE_URL_GITHUB',
  defaultValue:
      'https://raw.githubusercontent.com/Charon-1978/cycle_note/main/update/latest.json',
);

/// 兜底通道的 manifest。
///
/// 指向 NAS 上的静态目录，经 Cloudflare Tunnel 暴露为 **https**：
///   Cloudflare Tunnel dl.13146600.xyz → NAS Caddy :9000 → /data_n001/apk-share
///
/// 家里局域网直连仍可用 `http://192.168.31.48:9000/yueji/latest.json`
/// （network_security_config 已对该 IP 放行明文）。
///
/// 明文 HTTP 只在 network_security_config 里对 192.168.31.48 放行，其余强制 https。
const String kUpdateUrlNas = String.fromEnvironment(
  'UPDATE_URL_NAS',
  defaultValue: 'https://dl.13146600.xyz/yueji/latest.json',
);

/// 检测超时：GitHub 走 CDN，5 秒足够；NASHub 可能很慢，放宽到 12 秒。
const Duration kUpdateCheckTimeoutGitHub = Duration(seconds: 5);
const Duration kUpdateCheckTimeoutNas = Duration(seconds: 12);

/// 下载超时（连接/首包），不是整个文件的总时长。
const Duration kUpdateDownloadTimeout = Duration(seconds: 20);

const String kAppDisplayName = '月记';
