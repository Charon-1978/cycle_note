// test/widgets/stat_ring_test.dart
//
// 这些断言对应任务卡 P0-6 的验收标准：
//   1) 超预算时颜色为 calorieOver，且**不是** danger（红）—— ADR-3 回归保护
//   2) budget == 0 时不抛异常（除零保护）
//   3) 尺寸异常（size 小于线宽）不崩溃
//
// 运行：flutter test test/widgets/stat_ring_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/app/theme/app_colors.dart';
import 'package:cycle_note/core/widgets/charts/stat_ring.dart';

Widget _host(Widget child, {Brightness brightness = Brightness.light}) {
  final colors = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[colors],
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('StatRing 颜色语义（ADR-3）', () {
    testWidgets('未超预算 → calorieOk', (tester) async {
      final ring = StatRing(budget: 1800, intake: 1200, animate: false);
      await tester.pumpWidget(_host(ring));

      expect(ring.resolveArcColor(AppColors.light), AppColors.light.calorieOk);
      expect(
        ring.resolveArcColor(AppColors.light),
        isNot(AppColors.light.calorieOver),
      );
    });

    testWidgets('超预算 → calorieOver 且绝不是 danger（红）', (tester) async {
      final ring = StatRing(budget: 1500, intake: 1900, animate: false);
      await tester.pumpWidget(_host(ring));

      final color = ring.resolveArcColor(AppColors.light);
      expect(color, AppColors.light.calorieOver);
      // 核心断言：任何情况下都不允许把「超标」画成红色
      expect(color, isNot(AppColors.light.danger));
      expect(color, isNot(const Color(0xFFC62828)));
    });

    testWidgets('恰好等于预算 → 仍算未超（边界）', (tester) async {
      final ring = StatRing(budget: 1500, intake: 1500, animate: false);
      await tester.pumpWidget(_host(ring));

      expect(ring.resolveArcColor(AppColors.light), AppColors.light.calorieOk);
    });

    testWidgets('深色主题下取到深色值', (tester) async {
      final ring = StatRing(budget: 1500, intake: 1900, animate: false);
      await tester.pumpWidget(_host(ring, brightness: Brightness.dark));

      expect(ring.resolveArcColor(AppColors.dark), AppColors.dark.calorieOver);
      expect(
        ring.resolveArcColor(AppColors.dark),
        isNot(AppColors.dark.danger),
      );
    });
  });

  group('StatRing 健壮性', () {
    testWidgets('budget == 0 不抛异常（除零保护）', (tester) async {
      await tester.pumpWidget(
        _host(StatRing(budget: 0, intake: 1200, animate: false)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('budget 为负不抛异常', (tester) async {
      await tester.pumpWidget(
        _host(StatRing(budget: -100, intake: 50, animate: false)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('size 小于线宽时不崩溃', (tester) async {
      await tester.pumpWidget(
        _host(StatRing(budget: 1000, intake: 500, size: 8, strokeWidth: 12,
            animate: false)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('intake 超过预算时进度被 clamp 到 1（不越界）', (tester) async {
      final ring = StatRing(budget: 1000, intake: 5000, animate: false);
      await tester.pumpWidget(_host(ring));
      // 只要不抛异常即可；绘制时的 clamp 在 _intakeProgress 内部完成
      expect(tester.takeException(), isNull);
    });

    testWidgets('动画模式可正常渲染', (tester) async {
      await tester.pumpWidget(_host(const StatRing(budget: 1800, intake: 900)));
      await tester.pump(); // 起帧
      await tester.pump(const Duration(milliseconds: 300)); // 走完动画
      expect(tester.takeException(), isNull);
      expect(find.byType(StatRing), findsOneWidget);
    });

    testWidgets('centerChild 被渲染', (tester) async {
      await tester.pumpWidget(
        _host(
          StatRing(
            budget: 1800,
            intake: 900,
            animate: false,
            centerChild: const Text('剩余 900'),
          ),
        ),
      );
      expect(find.text('剩余 900'), findsOneWidget);
    });
  });
}
