// lib/features/me/pages/export_page.dart
//
// 导出数据页（P2-6 的 UI 入口）。
//
// 三个导出动作各写一个 CSV 到应用文档目录，完成后展示完整路径。
// 不做任何"自动上传"——导出是数据主权，去向由用户自己决定。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../data/local/database/database_provider.dart';
import '../../weight_loss/services/export_service.dart';

class ExportPage extends ConsumerStatefulWidget {
  const ExportPage({super.key});

  @override
  ConsumerState<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends ConsumerState<ExportPage> {
  bool _running = false;
  String? _result;

  Future<void> _export() async {
    setState(() {
      _running = true;
      _result = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final files = await const ExportService()
          .exportAll(ref.read(appDatabaseProvider), dir);
      setState(() {
        _result = files.map((f) => f.path).join('\n');
      });
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('导出失败：$e')));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('导出数据'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.pagePadding,
          vertical: AppTokens.spaceM,
        ),
        children: [
          Text(
            '把体重、运动、饮食记录导出为 CSV（UTF-8，Excel 可直接打开）。'
            '文件保存在应用文档目录，不会自动上传到任何服务器。',
            style: AppTokens.body.copyWith(
              color: scheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: AppTokens.cardGap),
          FilledButton.icon(
            onPressed: _running ? null : _export,
            icon: _running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(_running ? '导出中…' : '导出全部记录'),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppTokens.cardGap),
            Container(
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
                  Text('已导出 3 个文件：', style: AppTokens.title),
                  const SizedBox(height: AppTokens.spaceS),
                  Text(_result!, style: AppTokens.caption),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
