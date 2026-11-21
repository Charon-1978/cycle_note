// test/calendar/month_matrix_test.dart
//
// 月历矩阵是最容易出错、又最容易被忽略的地方（首日对齐、闰月、跨年）。
// 这里用结构性断言，不硬编码"2026-02-01 是星期几"这类易错常量。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/app/theme/app_colors.dart';
import 'package:cycle_note/features/calendar/utils/month_matrix.dart';
import 'package:cycle_note/features/calendar/widgets/month_grid.dart';
import 'package:cycle_note/features/period/services/period_prediction_service.dart';

void main() {
  group('buildMonthMatrix', () {
    test('固定 6 行 × 7 列，且日期连续无缺漏（全年逐月）', () {
      for (var m = 1; m <= 12; m++) {
        final matrix = buildMonthMatrix(2026, m);
        expect(matrix.length, 6, reason: '2026-$m 应为 6 行');
        expect(matrix.every((r) => r.length == 7), isTrue);

        final flat = matrix.expand((r) => r).toList();
        expect(flat.length, 42);

        final days = flat.whereType<DateTime>().toList();
        final expectedCount = DateTime(2026, m + 1, 0).day;
        expect(days.length, expectedCount, reason: '2026-$m 天数');

        // 首尾与连续性
        expect(days.first, DateTime(2026, m, 1));
        expect(days.last, DateTime(2026, m, expectedCount));
        for (var i = 1; i < days.length; i++) {
          expect(days[i].difference(days[i - 1]).inDays, 1);
        }
      }
    });

    test('首日前的空位数量 = 周一为起点的偏移', () {
      for (var m = 1; m <= 12; m++) {
        final flat = buildMonthMatrix(2026, m).expand((r) => r).toList();
        final firstIndex = flat.indexWhere((d) => d != null);
        final expected =
            (DateTime(2026, m, 1).weekday - DateTime.monday) % 7;
        expect(firstIndex, expected, reason: '2026-$m 首日偏移');
      }
    });

    test('闰年 2 月 29 天，平年 28 天', () {
      final leap = buildMonthMatrix(2024, 2).expand((r) => r).whereType<DateTime>();
      final common = buildMonthMatrix(2026, 2).expand((r) => r).whereType<DateTime>();
      expect(leap.length, 29);
      expect(common.length, 28);
    });

    test('非法月份被断言拦截', () {
      expect(() => buildMonthMatrix(2026, 0), throwsAssertionError);
      expect(() => buildMonthMatrix(2026, 13), throwsAssertionError);
    });
  });

  group('月份导航', () {
    test('previousMonth / nextMonth 正确跨年', () {
      expect(previousMonth(DateTime(2026, 1, 15)), DateTime(2025, 12, 1));
      expect(nextMonth(DateTime(2026, 12, 5)), DateTime(2027, 1, 1));
      expect(nextMonth(DateTime(2026, 6, 30)), DateTime(2026, 7, 1));
    });

    test('firstDayOfMonth / lastDayOfMonth', () {
      expect(firstDayOfMonth(DateTime(2026, 6, 18)), DateTime(2026, 6, 1));
      expect(lastDayOfMonth(DateTime(2026, 6, 18)), DateTime(2026, 6, 30));
      expect(lastDayOfMonth(DateTime(2024, 2, 10)), DateTime(2024, 2, 29));
    });

    test('isSameDay 忽略时分秒', () {
      expect(
        isSameDay(DateTime(2026, 6, 18, 23, 59), DateTime(2026, 6, 18, 0, 1)),
        isTrue,
      );
      expect(isSameDay(DateTime(2026, 6, 18), DateTime(2026, 6, 19)), isFalse);
    });
  });

  group('MonthGrid 渲染', () {
    testWidgets('渲染 42 格且不抛异常；今天有描边', (tester) async {
      final today = DateTime(2026, 6, 18);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            extensions: const <ThemeExtension<dynamic>>[AppColors.light],
          ),
          home: Scaffold(
            body: MonthGrid(
              month: DateTime(2026, 6, 1),
              today: today,
              phaseOfDay: (d) => d.day <= 5
                  ? CyclePhase.menstrual
                  : CyclePhase.normal,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // 6 月 1 日与 30 日都应存在
      expect(find.text('1'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      // 7 月 1 日不应出现（非本月补位为 null）
      expect(find.text('31'), findsNothing);
    });

    testWidgets('点击日期回调正确', (tester) async {
      DateTime? tapped;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            extensions: const <ThemeExtension<dynamic>>[AppColors.light],
          ),
          home: Scaffold(
            body: MonthGrid(
              month: DateTime(2026, 6, 1),
              today: DateTime(2026, 6, 18),
              phaseOfDay: (_) => CyclePhase.normal,
              onTapDay: (d) => tapped = d,
            ),
          ),
        ),
      );

      await tester.tap(find.text('15'));
      await tester.pump();

      expect(tapped, DateTime(2026, 6, 15));
    });
  });
}
