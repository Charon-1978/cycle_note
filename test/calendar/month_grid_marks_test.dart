// test/calendar/month_grid_marks_test.dart
//
// 日历标记的**配色契约**（2026-11 第二轮：用户反馈"标记不够明显"）。
//
// 锁四件事：
//   1) 已记录经期 = period 实心圆（不是淡底），且数字是白色
//   2) 预测经期   = period 淡底 + period 描边（与"已记录"必须能区分）
//   3) 易孕期 / 排卵日各有独立底色，且不是同一个颜色
//   4) 今天有外环，且不会把阶段色盖掉（阶段底色仍然存在）
//
// 这些断言故意写得"贴实现"：它们保护的是视觉语义，不是布局。
// 将来改配色时同步改这里，等于强制复核一次"记录/预测/易孕/排卵"是否还分得清。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/app/theme/app_colors.dart';
import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/features/calendar/widgets/month_grid.dart';
import 'package:cycle_note/features/period/services/period_prediction_service.dart';

/// 2026-11 的 5 号是星期四……取几天做标记。
final DateTime _month = DateTime(2026, 11);

Widget _host(Widget child) => MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Finder get _grid => find.byType(MonthGrid);

/// 网格里每个日期格子的装饰（底色 + 描边都画在同一层 Container 上）。
List<BoxDecoration> _decorations(WidgetTester tester) {
  return tester
      .widgetList<Container>(
        find.descendant(of: _grid, matching: find.byType(Container)),
      )
      .map((c) => c.decoration)
      .whereType<BoxDecoration>()
      .toList();
}

List<Color?> _cellColors(WidgetTester tester) =>
    _decorations(tester).map((d) => d.color).toList();

List<Color?> _cellBorderColors(WidgetTester tester) => _decorations(tester)
    .map((d) => (d.border as Border?)?.top.color)
    .toList();

void main() {
  testWidgets('已记录经期是实心 period 圆，且数字为白色', (tester) async {
    await tester.pumpWidget(
      _host(
        MonthGrid(
          month: _month,
          today: DateTime(2026, 11, 20),
          phaseOfDay: (d) =>
              d.day == 5 ? CyclePhase.menstrual : CyclePhase.normal,
          isRecorded: (d) => d.day == 5,
        ),
      ),
    );

    expect(
      _cellColors(tester).contains(AppColors.light.period),
      isTrue,
      reason: '已记录经期必须是 period 实心色，不能是淡底',
    );

    final text = tester.widget<Text>(find.text('5'));
    expect(text.style?.color, Colors.white, reason: '实心圆上的数字必须反白');
  });

  testWidgets('预测经期是淡底 + 描边，与已记录可区分', (tester) async {
    await tester.pumpWidget(
      _host(
        MonthGrid(
          month: _month,
          today: DateTime(2026, 11, 20),
          phaseOfDay: (d) =>
              d.day == 9 ? CyclePhase.menstrual : CyclePhase.normal,
          // 9 号只是预测，没有记录
          isRecorded: (_) => false,
        ),
      ),
    );

    final colors = _cellColors(tester);
    expect(
      colors.contains(AppColors.light.period),
      isFalse,
      reason: '预测经期不能用实心色，否则和真实记录分不清',
    );
    expect(
      colors.contains(AppColors.light.period.withAlpha(26)),
      isTrue,
      reason: '预测经期应是 period 淡底',
    );
    expect(
      _cellBorderColors(tester).contains(AppColors.light.period),
      isTrue,
      reason: '预测经期还需要 period 描边，远看才知道"这事还没发生"',
    );

    final text = tester.widget<Text>(find.text('9'));
    expect(text.style?.color, AppColors.light.period);
  });

  testWidgets('易孕期与排卵日各有底色，且颜色不同', (tester) async {
    await tester.pumpWidget(
      _host(
        MonthGrid(
          month: _month,
          today: DateTime(2026, 11, 20),
          phaseOfDay: (d) => switch (d.day) {
            10 => CyclePhase.fertile,
            11 => CyclePhase.ovulation,
            _ => CyclePhase.normal,
          },
        ),
      ),
    );

    final colors = _cellColors(tester);
    expect(
      colors.contains(AppColors.light.fertile),
      isTrue,
      reason: '易孕期底色',
    );
    expect(
      colors.contains(AppColors.light.ovulation),
      isTrue,
      reason: '排卵日底色',
    );

    // 三个阶段都是实心块 + 白字，只能靠**底色**区分，因此底色必须两两不同
    final fertile = tester.widget<Text>(find.text('10'));
    final ovulation = tester.widget<Text>(find.text('11'));
    expect(fertile.style?.color, Colors.white);
    expect(ovulation.style?.color, Colors.white);
    expect(AppColors.light.fertile, isNot(AppColors.light.ovulation));
    expect(AppColors.light.fertile, isNot(AppColors.light.period));
  });

  testWidgets('今天有外环，且不覆盖阶段底色', (tester) async {
    await tester.pumpWidget(
      _host(
        MonthGrid(
          month: _month,
          today: DateTime(2026, 11, 5),
          phaseOfDay: (d) =>
              d.day == 5 ? CyclePhase.fertile : CyclePhase.normal,
          isRecorded: (_) => false,
        ),
      ),
    );

    final rings = _decorations(tester)
        .where((d) => (d.border as Border?)?.top.color == AppColors.light.brand)
        .toList();
    expect(rings, hasLength(1), reason: '今天应恰好有一个品牌色外环');

    // 阶段底色仍在（今天不再用实心品牌色盖掉阶段）
    expect(
      _cellColors(tester).contains(AppColors.light.fertile),
      isTrue,
      reason: '今天的阶段底色不应被外环覆盖',
    );
  });
}
