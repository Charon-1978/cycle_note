// test/me/data_sources_test.dart
//
// P2-5「数据来源页」验收：
//   · 四条来源齐全：Mifflin-St Jeor / Katch-McArdle / Compendium / USDA
//   · 链接白名单：只允许 DATA_SOURCES.md 里出现过的 URL，防止编造链接
//   · 每条注明用途（"用于："）
//   · 免责声明文案在场
//
// 不测实际跳转（launchUrl 在测试环境会走平台通道，模拟器外无法验证）；
// 链接正确性靠白名单断言锁死。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/features/me/pages/data_sources_page.dart';

void main() {
  group('数据清单', () {
    test('四条来源齐全且标题可辨认', () {
      expect(kDataSourceEntries, hasLength(4));
      final titles = kDataSourceEntries.map((e) => e.title).join('|');
      expect(titles, contains('Mifflin-St Jeor'));
      expect(titles, contains('Katch-McArdle'));
      expect(titles, contains('Compendium'));
      expect(titles, contains('USDA'));
    });

    test('每条都注明用途与引文', () {
      for (final e in kDataSourceEntries) {
        expect(e.usedFor, isNotEmpty, reason: '${e.title} 缺用途说明');
        expect(e.citation, isNotEmpty, reason: '${e.title} 缺引文');
        expect(e.usedFor.startsWith('计算') || e.usedFor.isNotEmpty, isTrue);
      }
    });

    test('链接白名单：与 DATA_SOURCES.md 一致，不编造链接', () {
      // DATA_SOURCES.md §3 署名文案里背过书的 URL + PubMed 官方 DOI 落地页。
      // 有疑问的条目（如 Katch-McArdle 纸质专著）必须不带链接。
      const whitelist = <String>{
        'https://pacompendium.com',
        'https://fdc.nal.usda.gov',
        'https://pubmed.ncbi.nlm.nih.gov/2305711/',
      };
      for (final e in kDataSourceEntries) {
        if (e.url != null) {
          expect(
            whitelist.contains(e.url),
            isTrue,
            reason: '${e.url} 不在 DATA_SOURCES.md 背书过的白名单里',
          );
        }
      }
      // Katch-McArdle 是纸质专著，不应有链接
      final km = kDataSourceEntries
          .firstWhere((e) => e.title.contains('Katch-McArdle'));
      expect(km.url, isNull);
    });
  });

  group('页面', () {
    testWidgets('渲染四张来源卡、免责声明与链接文本', (tester) async {
      // 默认测试面太小，四张卡片在屏幕外；撑大视口一次渲染全量
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(home: DataSourcesPage()),
      );
      await tester.pumpAndSettle();

      for (final e in kDataSourceEntries) {
        expect(find.textContaining(e.title.split(' · ').first), findsWidgets,
            reason: '缺卡片：${e.title}');
        expect(find.textContaining(e.usedFor), findsWidgets);
      }
      expect(find.textContaining('不构成医疗建议'), findsOneWidget);
      for (final e in kDataSourceEntries) {
        if (e.url != null) {
          expect(find.textContaining(e.url!), findsOneWidget);
        }
      }
    });
  });
}
