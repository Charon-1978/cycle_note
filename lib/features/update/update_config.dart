// lib/features/update/update_config.dart
//
// 更新相关的**全部可配置项**集中在这里，替换仓库地址时只改这一个文件。
//
// 通道设计（2026-11 起：完全自托管脱钩，只发 GitHub）：
//   · 主通道   GitHub raw  —— manifest
//   · 镜像通道 jsDelivr     —— GitHub 同源内容的 CDN 镜像（不是自建服务器）
//   · 构建期覆盖 —— 用 --dart-define 覆盖任意一项，不改代码即可切换测试环境
//
// 为什么保留 jsDelivr：
//   它的内容**完全来自 GitHub 仓库**，只是 CDN 分发，属于同一条链路。
//   国内直连 raw.githubusercontent.com 偶发不通时，jsDelivr 通常可达。
//   两者版本、sha256 完全一致，不存在第二份产物。
//
// 隐私说明：App 只在用户点「检查更新」时才发起请求；
//   没有任何埋点、日志上报、账号体系；不连接任何自建服务器。

/// 当前版本。必须与 pubspec.yaml 的 `version:` 前段一致，
/// 由 test/update/version_sync_test.dart 在 CI 里强制校验。
const String kAppVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.1.2',
);

/// 主通道 manifest：GitHub raw（CDN 快、无需 API token）。
const String kUpdateUrlGitHub = String.fromEnvironment(
  'UPDATE_URL_GITHUB',
  defaultValue:
      'https://raw.githubusercontent.com/CharonCore/cycle_note/main/update/latest.json',
);

/// 镜像通道 manifest：jsDelivr（内容同源 GitHub，仅 CDN 不同）。
///
/// 版本号留空表示跟随 `main` 分支；发布打 tag 后可改成
/// `@v1.1.0` 固定版本，避免分支推进导致读到新 manifest。
const String kUpdateUrlMirror = String.fromEnvironment(
  'UPDATE_URL_MIRROR',
  defaultValue:
      'https://cdn.jsdelivr.net/gh/CharonCore/cycle_note@main/update/latest.json',
);

/// 检测超时：主通道 5 秒，镜像 8 秒（多一层 CDN 跳转）。
const Duration kUpdateCheckTimeoutGitHub = Duration(seconds: 5);
const Duration kUpdateCheckTimeoutMirror = Duration(seconds: 8);

/// 下载超时（连接/首包），不是整个文件的总时长。
const Duration kUpdateDownloadTimeout = Duration(seconds: 20);

const String kAppDisplayName = '月记';
