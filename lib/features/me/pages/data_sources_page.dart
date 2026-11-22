// lib/features/me/pages/data_sources_page.dart
//
// 数据来源页（P2-5）。
//
// 手册验收口径：
//   · 四条来源：Mifflin-St Jeor / Katch-McArdle / Compendium / USDA；
//   · 文案与 DATA_SOURCES.md 保持一致（同一份事实，两处消费）；
//   · **不编造链接**：只给能背书的 URL（pacompendium.com、fdc.nal.usda.gov、
//     PubMed PMID 2305711）。Katch-McArdle 出自纸质专著，没有官方稳定
//     网址，就给完整引文让读者自己去查——编一个"看起来像"的链接比
//     不给链接更糟。
//   · 每条注明数据在本应用里的用途，让用户知道"我的哪个数字是它算的"。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_tokens.dart';

class DataSourceEntry {
  const DataSourceEntry({
    required this.title,
    required this.usedFor,
    required this.citation,
    this.url,
  });

  final String title;
  final String usedFor;
  final String citation;
  final String? url;
}

const List<DataSourceEntry> kDataSourceEntries = [
  DataSourceEntry(
    title: '基础代谢公式 · Mifflin-St Jeor (1990)',
    usedFor: '计算你的每日热量预算（BMR 的默认公式）',
    citation: 'Mifflin MD, St Jeor ST, et al. A new predictive equation for '
        'resting energy expenditure in healthy individuals. '
        'Am J Clin Nutr. 1990.',
    url: 'https://pubmed.ncbi.nlm.nih.gov/2305711/',
  ),
  DataSourceEntry(
    title: '体成分公式 · Katch-McArdle',
    usedFor: '填写体脂率时改用该公式估算 BMR（对低体脂更准）',
    citation: 'Katch FI, McArdle WD. Nutrition, Weight Control, and Exercise.',
  ),
  DataSourceEntry(
    title: '运动能量消耗（MET） · Compendium of Physical Activities',
    usedFor: '运动记录页的能量消耗估算（MET × 3.5 × kg / 200 × min）',
    citation: 'Compendium of Physical Activities（2011/2024 Adult Compendium）。'
        'MET 值为学术公开发布，本应用仅取所需条目并署名。',
    url: 'https://pacompendium.com',
  ),
  DataSourceEntry(
    title: '食物营养参考 · USDA FoodData Central',
    usedFor: '食物库 203 条食材的热量与三大营养素（近似值，逐条标注 source）',
    citation: 'U.S. Department of Agriculture, Agricultural Research Service. '
        'FoodData Central. fdc.nal.usda.gov（CC0 1.0）。'
        '数值为同类食材换算的近似值，仅供日常估算。',
    url: 'https://fdc.nal.usda.gov',
  ),
];

class DataSourcesPage extends StatelessWidget {
  const DataSourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('数据来源'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.pagePadding,
          vertical: AppTokens.spaceM,
        ),
        children: [
          Text(
            '本应用使用的公开数据与公式。营养与热量建议仅供参考，不构成医疗建议。',
            style: AppTokens.body.copyWith(
              color: scheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: AppTokens.cardGap),
          for (final e in kDataSourceEntries) ...[
            _SourceCard(
              entry: e,
              onOpenUrl: e.url == null
                  ? null
                  : () => _launch(context, e.url!),
            ),
            const SizedBox(height: AppTokens.cardGap),
          ],
          Text(
            '食物库前 42 条为人工核对基准，新增条目均标注 source: usda_approx'
            '（近似值）。完整清单见项目内的 DATA_SOURCES.md。',
            style: AppTokens.caption.copyWith(
              color: scheme.onSurface.withAlpha(140),
            ),
          ),
          const SizedBox(height: AppTokens.cardGap),
          OutlinedButton.icon(
            onPressed: () => context.push('/me/privacy'),
            icon: const Icon(Icons.privacy_tip_outlined),
            label: const Text('查看隐私政策'),
          ),
        ],
      ),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // 无浏览器/链接打不开时给反馈，而不是静默失败
      messenger.showSnackBar(
        SnackBar(content: Text('无法打开链接：$url')),
      );
    }
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.entry, required this.onOpenUrl});

  final DataSourceEntry entry;
  final VoidCallback? onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceL),
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
          Text(entry.title, style: AppTokens.title),
          const SizedBox(height: AppTokens.spaceS),
          Text(
            '用于：${entry.usedFor}',
            style: AppTokens.body,
          ),
          const SizedBox(height: AppTokens.spaceS),
          Text(
            entry.citation,
            style: AppTokens.caption.copyWith(
              color: scheme.onSurface.withAlpha(150),
            ),
          ),
          if (entry.url != null) ...[
            const SizedBox(height: AppTokens.spaceS),
            InkWell(
              onTap: onOpenUrl,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.open_in_new, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      entry.url!,
                      style: AppTokens.caption.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
