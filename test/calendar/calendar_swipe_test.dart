// test/calendar/calendar_swipe_test.dart
//
// 日历左右滑动切月（2026-11 新增交互）的验收：
//   · 手指往左划 → 下个月；往右划 → 上个月（与主流日历一致）
//   · 年视图下左右划 → 切年（不是切月）
//   · 慢慢拖一点点就抬手（速度不够）→ 不翻页，避免误触
//   · 滑动不能被"点日期"抢走：点某天仍然能开弹层
//
// 用 fling 触发：Flutter 的手势竞技场里，水平拖动会被 GestureDetector 的
// HorizontalDragGestureRecognizer 认领，垂直滚动不受影响。

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';
import 'package:cycle_note/features/calendar/pages/calendar_page.dart';
import 'package:cycle_note/features/calendar/widgets/month_grid.dart';
import 'package:cycle_note/features/calendar/widgets/year_overview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  final now = DateTime.now();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpCalendar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: buildLightTheme(), home: const CalendarPage()),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  String monthTitle(int year, int month) => '$year 年 $month 月';

  int nextMonthOf(int year, int month) => month == 12 ? 1 : month + 1;
  int prevMonthOf(int year, int month) => month == 1 ? 12 : month - 1;
  int yearOfNext(int year, int month) => month == 12 ? year + 1 : year;
  int yearOfPrev(int year, int month) => month == 1 ? year - 1 : year;

  testWidgets('左滑 → 下个月，右滑 → 上个月', (tester) async {
    await pumpCalendar(tester);
    expect(find.text(monthTitle(now.year, now.month)), findsOneWidget);

    await tester.fling(
      find.byType(MonthGrid),
      const Offset(-400, 0),
      1200,
    );
    await tester.pumpAndSettle();

    final nm = nextMonthOf(now.year, now.month);
    expect(
      find.text(monthTitle(yearOfNext(now.year, now.month), nm)),
      findsOneWidget,
      reason: '左滑应翻到下个月',
    );

    await tester.fling(
      find.byType(MonthGrid),
      const Offset(400, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(monthTitle(now.year, now.month)),
      findsOneWidget,
      reason: '右滑应翻回上个月',
    );
    // 再往右滑一次，落到上个月
    await tester.fling(
      find.byType(MonthGrid),
      const Offset(400, 0),
      1200,
    );
    await tester.pumpAndSettle();
    final pm = prevMonthOf(now.year, now.month);
    expect(
      find.text(monthTitle(yearOfPrev(now.year, now.month), pm)),
      findsOneWidget,
    );
  });

  testWidgets('年视图下左右滑 → 切年', (tester) async {
    await pumpCalendar(tester);
    await tester.tap(find.byTooltip('看全年'));
    await tester.pumpAndSettle();
    expect(find.byType(YearOverview), findsOneWidget);

    await tester.fling(
      find.byType(YearOverview),
      const Offset(-400, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.text('${now.year + 1} 年'), findsWidgets);
    expect(find.byType(YearOverview), findsOneWidget, reason: '仍然停在年视图');
  });

  testWidgets('速度不够的轻拖不翻页（误触保护）', (tester) async {
    await pumpCalendar(tester);

    await tester.drag(find.byType(MonthGrid), const Offset(-40, 0));
    await tester.pumpAndSettle();

    expect(find.text(monthTitle(now.year, now.month)), findsOneWidget);
  });

  testWidgets('滑动之后点某天仍然能开弹层（手势不互相抢）', (tester) async {
    await pumpCalendar(tester);

    await tester.fling(find.byType(MonthGrid), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();

    // 翻到的新月份里点 15 号
    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('补记经期'), findsWidgets);
  });
}
