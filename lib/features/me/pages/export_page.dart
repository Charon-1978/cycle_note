// lib/features/me/pages/export_page.dart
//
// 数据管理页（P2-6 导出 + P5-1 导入 + 备份恢复）。
//
// 三个动作的分工要写清楚，否则用户会以为"恢复备份"能换机：
//   · 导出 CSV —— 明文表格，**可跨设备/跨版本**，用于迁移与长期留存；
//   · 导入 CSV —— 把导出的表读回来（幂等、带去重），换机后靠它恢复；
//   · 恢复备份 —— 复制本机 App 内的 sqlite 备份，**只适用于本机升级失败回滚**
//                 （库由 SQLCipher 加密，密钥在系统 Keystore，换机打不开）。
//
// 不做任何"自动上传"——导出是数据主权，去向由用户自己决定。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/database/db_backup.dart';
import '../../../core/database/encrypted_database_opener.dart';
import '../../../data/local/database/database_provider.dart';
import '../../weight_loss/services/export_service.dart';
import '../../weight_loss/services/import_service.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  bool _running = false;
  String? _result;
  ImportReport? _report;

  /// 「最近备份 11-22 11:52 · 共 1 份」这句摘要。
  /// 原来只有一个按钮，用户不知道会回到哪个时刻、有没有备份可恢复。
  String _backupSummary = '正在读取备份…';

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshBackupSummary);
  }

  Future<void> _refreshBackupSummary() async {
    String text;
    try {
      final backups = await DbBackup.listBackups();
      if (backups.isEmpty) {
        text = '还没有备份（升级失败时才需要它）';
      } else {
        final latest = await backups.first.stat();
        final m = latest.modified;
        final hh = m.hour.toString().padLeft(2, '0');
        final mm = m.minute.toString().padLeft(2, '0');
        text = '最近备份 ${m.month}-${m.day} $hh:$mm · 共 ${backups.length} 份';
      }
    } catch (_) {
      text = '备份状态读取失败（不影响导出）';
    }
    if (mounted) setState(() => _backupSummary = text);
  }

  Future<void> _export() async {
    setState(() {
      _running = true;
      _result = null;
      _report = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = await const ExportService()
          .exportAll(ref.read(appDatabaseProvider), dir);
      if (!mounted) return;
      setState(() {
        _result = files.map((f) => f.path).join('\n');
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('导出失败：$e')));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  /// 从本机导出目录挑文件导入。
  ///
  /// 为什么不用系统文件选择器（file_picker）：该插件 11.x 的 Kotlin 源在
  /// 本环境（AGP 9 / Gradle 9.1）下未被编译，registrant 直接找不到插件类。
  /// 为了不再引入一个要钉版的依赖，这里改成「扫描自己的导出目录」——
  /// 导出与导入用同一个目录，往返验证天然成立。
  Future<void> _importFromFiles() async {
    final messenger = ScaffoldMessenger.of(context);
    final dir = await getApplicationDocumentsDirectory();
    final files = <File>[];
    await for (final e in dir.list()) {
      if (e is File && e.path.toLowerCase().endsWith('.csv')) {
        final name = e.uri.pathSegments.last;
        if (name.startsWith('yueji_')) files.add(e);
      }
    }
    files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    if (!mounted) return;
    if (files.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('导出目录里没有 CSV：\n${dir.path}'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final selected = await showDialog<List<File>>(
      context: context,
      builder: (c) {
        final picked = <String>{};
        return StatefulBuilder(
          builder: (c, setDialog) => AlertDialog(
            title: const Text('选择要导入的 CSV'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final f in files)
                    CheckboxListTile(
                      dense: true,
                      value: picked.contains(f.path),
                      title: Text(
                        // 文件名很长（yueji_period_days_20261122_1228.csv），
                        // 窄屏会从中间断词成 "…1228.cs / v"。这里只留一行 + 省略号，
                        // 完整名字放到语义标签里，读屏仍能拿到全名。
                        f.uri.pathSegments.last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        semanticsLabel: f.uri.pathSegments.last,
                        style: AppTokens.caption,
                      ),
                      subtitle: Text(
                        '${(f.lengthSync() / 1024).toStringAsFixed(1)} KB',
                        style: AppTokens.caption,
                      ),
                      onChanged: (v) => setDialog(() {
                        if (v == true) {
                          picked.add(f.path);
                        } else {
                          picked.remove(f.path);
                        }
                      }),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(c).pop(null),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: picked.isEmpty
                    ? null
                    : () => Navigator.of(c).pop(
                          files.where((f) => picked.contains(f.path)).toList(),
                        ),
                child: Text('导入 ${picked.length} 个'),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected.isEmpty) return;
    await _runImport(selected);
  }

  /// 从剪贴板导入：换机时把旧机导出的 CSV 内容通过微信/记事本转过来粘贴。
  /// 单表一次；多表请分别复制。
  Future<void> _importFromClipboard() async {
    final messenger = ScaffoldMessenger.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('剪贴板里没有文本')),
      );
      return;
    }
    final tmpDir = await getTemporaryDirectory();
    final f = File('${tmpDir.path}/clipboard_import.csv');
    await f.writeAsString(text);
    if (!mounted) return;
    await _runImport([f]);
  }

  /// 统一的导入执行 + 报告展示。
  Future<void> _runImport(List<File> files) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _running = true;
      _result = null;
      _report = null;
    });

    try {
      final report = await const ImportService()
          .importFiles(ref.read(appDatabaseProvider), files);
      if (!mounted) return;

      // 导入后让所有派生 Provider 重建，否则页面仍显示旧数据
      ref.invalidate(appDatabaseProvider);
      setState(() => _report = report);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '已导入 ${report.totalImported} 条'
            '${report.totalSkipped > 0 ? '，跳过 ${report.totalSkipped} 条' : ''}',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('导入失败：$e')));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _restoreBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('恢复最近一次备份？'),
        content: const Text(
          '会用 App 内的备份文件覆盖当前数据库，当前数据将丢失。\n\n'
          '这条路径只用于「升级失败后回滚」，不能换机使用'
          '（库是加密的，密钥在本机系统里）。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;

    setState(() {
      _running = true;
      _result = null;
      _report = null;
    });

    try {
      final dbPath = await EncryptedDatabaseOpener.resolvePath();
      // 先释放连接：Windows/Android 上文件被占用时无法替换
      await ref.read(appDatabaseProvider).close();
      final restored = await DbBackup.restoreLatest(dbPath);
      if (!mounted) return;
      ref.invalidate(appDatabaseProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(restored ? '已恢复备份，数据已重新加载' : '没有找到可用的备份'),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('恢复失败：$e')));
    } finally {
      if (mounted) setState(() => _running = false);
      await _refreshBackupSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: const Text('数据管理'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.pagePadding,
          vertical: AppTokens.spaceM,
        ),
        children: [
          Text(
            '导出为 CSV（UTF-8，Excel 可直接打开），不自动上传任何服务器。'
            '换手机时：旧机导出 → 新机导入。',
            style: AppTokens.body.copyWith(
              color: scheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: AppTokens.cardGap),

          FilledButton.icon(
            onPressed: _running ? null : _export,
            icon: const Icon(Icons.download_outlined),
            label: Text(_running ? '处理中…' : '导出全部记录（5 个 CSV）'),
          ),
          const SizedBox(height: AppTokens.spaceS),
          OutlinedButton.icon(
            onPressed: _running ? null : _importFromFiles,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('从本机 CSV 导入'),
          ),
          const SizedBox(height: AppTokens.spaceS),
          OutlinedButton.icon(
            onPressed: _running ? null : _importFromClipboard,
            icon: const Icon(Icons.content_paste_outlined),
            label: const Text('从剪贴板导入'),
          ),
          const SizedBox(height: AppTokens.spaceS),
          TextButton.icon(
            onPressed: _running ? null : _restoreBackup,
            icon: const Icon(Icons.restore),
            label: const Text('恢复本机备份（升级失败回滚用）'),
          ),
          Text(
            _backupSummary,
            textAlign: TextAlign.center,
            style: AppTokens.caption.copyWith(
              color: scheme.onSurface.withAlpha(130),
            ),
          ),

          if (_result != null) ...[
            const SizedBox(height: AppTokens.cardGap),
            _Card(
              title: '已导出 ${_result!.split('\n').length} 个文件：',
              body: _result!,
            ),
          ],

          if (report != null) ...[
            const SizedBox(height: AppTokens.cardGap),
            _Card(title: '导入结果', body: _reportText(report)),
          ],

          const SizedBox(height: AppTokens.cardGap),
          Text(
            '说明：导出文件不含任何密钥或系统路径；导入按「时间 + 内容」去重，'
            '同一批文件重复导入不会产生重复数据。',
            style: AppTokens.caption.copyWith(
              color: scheme.onSurface.withAlpha(140),
            ),
          ),
        ],
      ),
    );
  }

  static String _reportText(ImportReport r) {
    const names = {
      ImportKind.weight: '体重',
      ImportKind.exercise: '运动',
      ImportKind.meal: '饮食',
      ImportKind.periodCycle: '经期',
      ImportKind.periodDay: '逐日记录',
    };
    final lines = <String>[];
    // imported 与 skipped 的键可能不重合（全跳过时 imported 为空），取并集
    final kinds = {...r.imported.keys, ...r.skipped.keys};
    for (final k in kinds) {
      final ok = r.imported[k] ?? 0;
      final skip = r.skipped[k] ?? 0;
      lines.add('${names[k] ?? k}：导入 $ok 条'
          '${skip > 0 ? '，跳过 $skip 条' : ''}');
    }
    if (lines.isEmpty) lines.add('没有可导入的数据');
    if (r.messages.isNotEmpty) {
      lines.add('');
      lines.add('需注意：');
      lines.addAll(r.messages.take(8));
      if (r.messages.length > 8) {
        lines.add('… 另有 ${r.messages.length - 8} 条');
      }
    }
    return lines.join('\n');
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceM),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppTokens.borderM,
        border: Border.all(
          color: scheme.onSurface.withAlpha(20),
          width: AppTokens.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTokens.title),
          const SizedBox(height: AppTokens.spaceS),
          SelectableText(body, style: AppTokens.caption),
        ],
      ),
    );
  }
}
