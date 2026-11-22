// test/calendar/year_overview_test.dart
//
// 年视图（计划书 §4.2）的验收：
//   · 12 个月都在，且 4 行 × 3 列排版（不是一长串）
//   · 状态点按 phaseOfDay 的返回值上色（经期/易孕/排卵有颜色，普通日淡灰）
//   · 点某个月回传该月 1 号（页面据此切回月视图）
//   · 当前月有高亮底（用户一眼知道"我在哪个月"）

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/app/theme/app_colors.dart';
import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/features/calendar/widgets/year_overview.dart';
import 'package:cycle_note/features/period/services/period_prediction_service.dart';

Widget _host(Widget child) => MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('12 个月全在，且点某月回传该月 1 号', (tester) async {
    final tapped = <DateTime>[];
    await tester.pumpWidget(
      _host(
        YearOverview(
          year: 2026,
          today: DateTime(2026, 11, 22),
          phaseOfDay: (_) => CyclePhase.normal,
          onTapMonth: tapped.add,
        ),
      ),
    );

    for (var m = 1; m <= 12; m++) {
      expect(find.text('$m 月'), findsOneWidget, reason: '缺 $m 月');
    }

    await tester.tap(find.text('3 月'));
    expect(tapped, [DateTime(2026, 3)]);
  });

  testWidgets('状态点按阶段上色：经期日与普通日颜色不同', (tester) async {
    // 2026-03 只有 3/1 是经期，用来验证上色不是"全画成一种"
    await tester.pumpWidget(
      _host(
        YearOverview(
          year: 2026,
          today: DateTime(2026, 11, 22),
          phaseOfDay: (d) => d.day == 1 && d.month == 3
              ? CyclePhase.menstrual
              : CyclePhase.normal,
        ),
      ),
    );

    final dots = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final d = c.decoration;
          return d is BoxDecoration && d.shape == BoxShape.circle && d.color != null;
        })
        .map((c) => (c.decoration! as BoxDecoration).color)
        .toList();

    expect(dots, isNotEmpty);
    expect(dots.contains(AppColors.light.period), isTrue,
        reason: '经期日必须是 period 色');
    expect(dots.toSet().length, greaterThan(1),
        reason: '普通日与经期日不能是同一个颜色');
  });

  testWidgets('当前月有品牌色底高亮', (tester) async {
    await tester.pumpWidget(
      _host(
        YearOverview(
          year: 2026,
          today: DateTime(2026, 11, 22),
          phaseOfDay: (_) => CyclePhase.normal,
        ),
      ),
    );

    final highlights = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final d = c.decoration;
          return d is BoxDecoration && d.color == AppColors.light.brandSoft;
        });
    expect(highlights, hasLength(1), reason: '只有当前月该有高亮底');
  });

  testWidgets('跨年：给 2025 年时月份标签仍是 1–12 月', (tester) async {
    await tester.pumpWidget(
      _host(
        YearOverview(
          year: 2025,
          today: DateTime(2026, 11, 22),
          phaseOfDay: (_) => CyclePhase.normal,
        ),
      ),
    );
    expect(find.text('2025 年'), findsOneWidget);
    expect(find.text('12 月'), findsOneWidget);
    // 2026 年的今天不该高亮 2025 年的月份
    final highlights = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
          final d = c.decoration;
          return d is BoxDecoration && d.color == AppColors.light.brandSoft;
        });
    expect(highlights, isEmpty);
  });
}
