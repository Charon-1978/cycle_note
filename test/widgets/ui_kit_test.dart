// test/widgets/ui_kit_test.dart
//
// 2026-11 视觉升级新增的四件套（SoftCard / SectionHeader / PillTag /
// QuickActionGrid）的组件级验收：
//   · 浅色 / 深色两套都能渲染，不抛异常；
//   · 颜色全部来自 AppColors（不硬编码），所以深浅色下卡片底色必须不同；
//   · 可点击时能响应，不可点击时不抢焦点；
//   · 空 action 时不显示箭头按钮。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/app/theme/app_colors.dart';
import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/core/widgets/feedback/pill_tag.dart';
import 'package:cycle_note/core/widgets/input/quick_action_grid.dart';
import 'package:cycle_note/core/widgets/surface/section_header.dart';
import 'package:cycle_note/core/widgets/surface/soft_card.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light ? buildLightTheme() : buildDarkTheme(),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('SoftCard', () {
    testWidgets('渲染内容并带品牌底色', (tester) async {
      await tester.pumpWidget(_host(const SoftCard(child: Text('卡片内容'))));
      expect(find.text('卡片内容'), findsOneWidget);

      final box = tester.widget<Container>(
        find.descendant(of: find.byType(SoftCard), matching: find.byType(Container)).first,
      );
      final deco = box.decoration! as BoxDecoration;
      expect(deco.color, AppColors.light.surface);
      expect(deco.borderRadius, BorderRadius.circular(20));
    });

    testWidgets('深色下卡片底色与浅色不同（证明走的是主题色而不是写死白色）', (tester) async {
      await tester.pumpWidget(
        _host(const SoftCard(child: Text('x')), brightness: Brightness.dark),
      );
      final box = tester.widget<Container>(
        find.descendant(of: find.byType(SoftCard), matching: find.byType(Container)).first,
      );
      final deco = box.decoration! as BoxDecoration;
      expect(deco.color, AppColors.dark.surface);
      expect(deco.color, isNot(AppColors.light.surface));
    });

    testWidgets('onTap 为 null 时不铺 InkWell 的点击语义', (tester) async {
      await tester.pumpWidget(_host(const SoftCard(child: Text('静止'))));
      expect(find.byType(InkWell), findsOneWidget); // 组件内部始终有 InkWell
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });

    testWidgets('onTap 非空时可点击', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        _host(SoftCard(onTap: () => tapped++, child: const Text('可点'))),
      );
      await tester.tap(find.text('可点'));
      expect(tapped, 1);
    });
  });

  group('SectionHeader', () {
    testWidgets('有 actionLabel 时出现右箭头；没有时不出现', (tester) async {
      await tester.pumpWidget(
        _host(const SectionHeader(title: '记录', actionLabel: '全部')),
      );
      expect(find.text('记录'), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.pumpWidget(_host(const SectionHeader(title: '记录')));
      expect(find.text('全部'), findsNothing);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });
  });

  group('PillTag', () {
    testWidgets('五种 tone 用各自的语义色', (tester) async {
      await tester.pumpWidget(
        _host(
          const Column(
            children: [
              PillTag(label: '经期', tone: PillTone.period),
              PillTag(label: '易孕', tone: PillTone.fertile),
              PillTag(label: '排卵', tone: PillTone.ovulation),
              PillTag(label: '超标', tone: PillTone.over),
              PillTag(label: '普通', tone: PillTone.neutral),
            ],
          ),
        ),
      );
      expect(find.text('经期'), findsOneWidget);
      final periodText = tester.widget<Text>(find.text('经期'));
      expect(periodText.style?.color, AppColors.light.period);

      final overText = tester.widget<Text>(find.text('超标'));
      expect(overText.style?.color, AppColors.light.calorieOver);
    });
  });

  group('QuickActionGrid', () {
    testWidgets('四个入口都能点，整块可点', (tester) async {
      final hits = <String>[];
      await tester.pumpWidget(
        _host(
          QuickActionGrid(
            actions: [
              QuickAction(icon: Icons.add, label: '甲', onTap: () => hits.add('甲')),
              QuickAction(icon: Icons.add, label: '乙', onTap: () => hits.add('乙')),
              QuickAction(icon: Icons.add, label: '丙', onTap: () => hits.add('丙')),
              QuickAction(icon: Icons.add, label: '丁', onTap: () => hits.add('丁')),
            ],
          ),
        ),
      );

      for (final label in ['甲', '乙', '丙', '丁']) {
        await tester.tap(find.text(label));
      }
      expect(hits, ['甲', '乙', '丙', '丁']);
    });
  });
}
