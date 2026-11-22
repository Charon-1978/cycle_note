// lib/features/update/update_page.dart
//
// 「检查更新」页。
//
// 交互刻意做得"手点一次、过程可见、失败可解释"：
//   · 不自动检查（省电 + 隐私：没点就不联网）；
//   · 检测阶段显示正在试哪个通道（GitHub / jsDelivr），失败原因就地显示；
//   · 下载显示百分比与来源；sha256 不符会自动换下一个地址重下；
//   · 装之前先检查"安装未知来源应用"权限，没有就引导去系统设置，而不是直接报错。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_tokens.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/surface/soft_card.dart';
import 'update_config.dart';
import 'update_providers.dart';
import 'update_service.dart';

class UpdatePage extends ConsumerStatefulWidget {
  const UpdatePage({super.key});

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

enum _Stage { idle, checking, latest, found, error, downloading, ready }

class _UpdatePageState extends ConsumerState<UpdatePage> {
  _Stage _stage = _Stage.idle;
  UpdateCheckResult? _result;
  File? _apk;
  double? _progress;
  String? _downloadSource;
  String? _message;

  UpdateService get _service => ref.read(updateServiceProvider);

  Future<void> _check() async {
    setState(() {
      _stage = _Stage.checking;
      _message = null;
      _result = null;
      _apk = null;
      _progress = null;
    });

    final r = await _service.check();
    if (!mounted) return;
    setState(() {
      _result = r;
      if (r.error != null) {
        _stage = _Stage.error;
        _message = r.error;
      } else if (r.hasUpdate) {
        _stage = _Stage.found;
      } else {
        _stage = _Stage.latest;
      }
    });
  }

  Future<void> _download() async {
    final manifest = _result?.manifest;
    if (manifest == null) return;

    setState(() {
      _stage = _Stage.downloading;
      _progress = 0;
      _message = null;
      _downloadSource = _result?.source?.label;
    });

    try {
      final file = await _service.download(
        manifest,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _progress = total == null || total <= 0 ? null : received / total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _apk = file;
        _stage = _Stage.ready;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _message = '$e';
      });
    }
  }

  Future<void> _install() async {
    final apk = _apk;
    if (apk == null) return;

    final ok = await _service.canInstall();
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _message = '系统还不允许安装未知来源应用，已为你打开设置页；'
            '打开「允许来自此来源」后回来再点安装。';
      });
      await _service.openInstallSettings();
      return;
    }
    await _service.install(apk);
    if (!mounted) return;
    setState(() {
      _message = '已交给系统安装器，按提示完成安装即可。';
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('检查更新')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.spaceL,
          AppTokens.spaceM,
          AppTokens.spaceL,
          AppTokens.spaceXl,
        ),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前版本',
                    style: AppTokens.caption.copyWith(
                      color: scheme.onSurface.withAlpha(150),
                    )),
                const SizedBox(height: AppTokens.spaceXs),
                Text('v$kAppVersion', style: AppTokens.headline),
                const SizedBox(height: AppTokens.spaceM),
                Text(
                  '更新检测走两条线：先 GitHub 直连，拉不到再换 jsDelivr 镜像（同源内容）。'
                  '只有你点「检查更新」时才会联网。',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(150),
                  ),
                ),
                const SizedBox(height: AppTokens.spaceM),
                SizedBox(
                  width: double.infinity,
                  height: AppTokens.minTouchTarget,
                  child: FilledButton.icon(
                    onPressed: _stage == _Stage.checking ||
                            _stage == _Stage.downloading
                        ? null
                        : _check,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _stage == _Stage.checking ? '正在检查…' : '检查更新',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.cardGap),
          if (_stage == _Stage.checking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.spaceL),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_stage == _Stage.latest)
            SoftCard(
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: colors.fertile),
                  const SizedBox(width: AppTokens.spaceM),
                  Expanded(
                    child: Text(
                      '已是最新版本',
                      style: AppTokens.title,
                    ),
                  ),
                ],
              ),
            ),
          if (_result?.hasUpdate ?? false) _updateCard(context),
          if (_stage == _Stage.error)
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.cloud_off_outlined, color: colors.danger),
                      const SizedBox(width: AppTokens.spaceM),
                      Expanded(
                        child: Text('检查/下载失败', style: AppTokens.title),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceS),
                  Text(
                    _message ?? '未知错误',
                    style: AppTokens.body.copyWith(
                      color: scheme.onSurface.withAlpha(170),
                    ),
                  ),
                  if (_result?.triedSources.isNotEmpty ?? false) ...[
                    const SizedBox(height: AppTokens.spaceS),
                    Text(
                      '已尝试：${_result!.triedSources.map((s) => s.label).join(' → ')}',
                      style: AppTokens.caption.copyWith(
                        color: scheme.onSurface.withAlpha(120),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTokens.spaceM),
                  OutlinedButton(
                    onPressed: _check,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          if (_message != null && _stage != _Stage.error)
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spaceM),
              child: Text(
                _message!,
                style: AppTokens.caption.copyWith(
                  color: scheme.onSurface.withAlpha(150),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _updateCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final m = _result!.manifest!;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_alt, color: colors.brand),
              const SizedBox(width: AppTokens.spaceM),
              Expanded(
                child: Text(
                  '发现新版本 v${m.version}',
                  style: AppTokens.title,
                ),
              ),
              if (_result!.source != null)
                Text(
                  '来源 ${_result!.source!.label}',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(120),
                  ),
                ),
            ],
          ),
          if (m.notes.trim().isNotEmpty) ...[
            const SizedBox(height: AppTokens.spaceM),
            Text(
              m.notes.trim(),
              style: AppTokens.body.copyWith(
                color: scheme.onSurface.withAlpha(180),
              ),
            ),
          ],
          const SizedBox(height: AppTokens.spaceM),
          if (_stage == _Stage.downloading) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: AppTokens.spaceXs),
            Text(
              _progress == null
                  ? '正在下载（大小未知）…'
                  : '正在下载 ${(_progress! * 100).toStringAsFixed(0)}%',
              style: AppTokens.caption.copyWith(
                color: scheme.onSurface.withAlpha(150),
              ),
            ),
          ] else if (_stage == _Stage.ready) ...[
            Text(
              '已下载，等待安装',
              style: AppTokens.body.copyWith(color: colors.fertile),
            ),
          ],
          const SizedBox(height: AppTokens.spaceM),
          SizedBox(
            width: double.infinity,
            height: AppTokens.minTouchTarget,
            child: FilledButton.icon(
              onPressed: _stage == _Stage.ready
                  ? _install
                  : (_stage == _Stage.downloading ? null : _download),
              icon: Icon(
                _stage == _Stage.ready
                    ? Icons.install_mobile_outlined
                    : Icons.download_outlined,
              ),
              label: Text(
                _stage == _Stage.ready
                    ? '安装'
                    : (_downloadSource == null
                        ? '下载安装包'
                        : '下载安装包（$_downloadSource）'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
