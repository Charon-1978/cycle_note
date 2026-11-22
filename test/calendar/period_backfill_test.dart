// test/calendar/period_backfill_test.dart
//
// P4-1「日历补记历史经期」的交互验收。
// 锁住三件事：
//   1) 点过去某一天 → 弹层给出「补记经期」入口（不再只有"知道了"）；
//   2) 点补记按钮 → 数据落库、弹层关闭、SnackBar 反馈；
//   3) 点已在经期内的一天 → 可「经期到这天结束」与「删除这段经期」。
//
// 日期一律相对今天构造：测试在月初跑时自动翻到上个月，
// 避免"补记的是未来日期"被合法拒绝。

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
import 'package:cycle_note/features/period/data/period_repository.dart';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PeriodRepository repo;

  final today = dateOnly(DateTime.now());
  // 5 天前：既不是今天、也不在预测区间之外，适合当"历史日期"
  final target = today.subtract(const Duration(days: 5));

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PeriodRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpCalendar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const CalendarPage(),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // 目标日期在上个月时，先翻页（否则格子里找不到）
    if (target.month != today.month || target.year != today.year) {
      await tester.tap(find.byTooltip('上个月'));
      await tester.pumpAndSettle();
    }
  }

  Finder dayCell(int day) => find.descendant(
        of: find.byType(MonthGrid),
        matching: find.text('$day'),
      );

  group('补记入口（2026-11-22 新流程：开始日 → 结束日）', () {
    /// 把日历翻到 [date] 所在的月份（先回到今天，再按月差前后翻）。
    Future<void> goToMonth(WidgetTester tester, DateTime date) async {
      await tester.tap(find.text('今天'));
      await tester.pumpAndSettle();
      final delta = (date.year * 12 + date.month) -
          (today.year * 12 + today.month);
      for (var i = 0; i < delta.abs(); i++) {
        await tester.tap(find.byTooltip(delta < 0 ? '上个月' : '下个月'));
        await tester.pumpAndSettle();
      }
    }

    /// 打开某天的弹层，再点「X月X日 来经期，选择结束日」，进入结束日选择器。
    Future<void> openEndPicker(WidgetTester tester, DateTime start) async {
      await goToMonth(tester, start);
      await tester.tap(dayCell(start.day));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('来经期，选择结束日'));
      await tester.pumpAndSettle();
    }

    testWidgets('点过去的某天 → 出现补记入口，不再有 3–7 天快捷选项', (tester) async {
      await pumpCalendar(tester);

      await tester.tap(dayCell(target.day));
      await tester.pumpAndSettle();

      expect(find.text('补记经期'), findsOneWidget);
      expect(
        find.textContaining('${target.month}月${target.day}日 来经期'),
        findsOneWidget,
      );
      // 旧流程的天数 chip 必须消失（异常经期可能超过 7 天）
      expect(find.widgetWithText(ChoiceChip, '7 天'), findsNothing);
      expect(find.text('3 天'), findsNothing);
    });

    testWidgets('选结束日 → 范围外的日期不可点，今天之后不可点', (tester) async {
      await pumpCalendar(tester);
      await openEndPicker(tester, target);

      expect(find.text('选择结束日'), findsOneWidget);
      // target = 今天 - 5 → 可选 6 天（含今天）
      expect(find.textContaining('最长可到'), findsOneWidget);

      // 起始日之前的那天（target - 1）应是变淡的不可点格子
      final grid = tester.widget<MonthGrid>(
        find.byType(MonthGrid).last,
      );
      expect(grid.isEnabled!(target.subtract(const Duration(days: 1))), isFalse);
      expect(grid.isEnabled!(today), isTrue);
      expect(grid.isEnabled!(today.add(const Duration(days: 1))), isFalse);
    });

    /// 在选择器里选一天（跨月时先翻到那个月）。
    Future<void> pickDay(
      WidgetTester tester,
      DateTime cursorStart,
      DateTime day,
    ) async {
      final delta =
          (day.year * 12 + day.month) - (cursorStart.year * 12 + cursorStart.month);
      for (var i = 0; i < delta.abs(); i++) {
        await tester.tap(find.byTooltip(delta < 0 ? '上个月' : '下个月').last);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.descendant(
        of: find.byType(MonthGrid).last,
        matching: find.text('${day.day}'),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('选结束日 → 落库、弹层关闭、给出反馈', (tester) async {
      await pumpCalendar(tester);
      await openEndPicker(tester, target);

      // 选到 target + 3 天作为结束日
      final end = target.add(const Duration(days: 3));
      await pickDay(tester, target, end);

      expect(find.textContaining('共 4 天'), findsOneWidget);
      await tester.tap(find.textContaining('补记 ${target.month}月${target.day}日 – '));
      await tester.pumpAndSettle();

      final rows = await db.select(db.periodCycles).get();
      expect(rows, hasLength(1));
      expect(rows.single.startDate, target);
      expect(rows.single.endDate, end);
      expect(rows.single.periodLength, 4);
      expect(find.text('补记经期'), findsNothing);
      expect(find.textContaining('已补记'), findsOneWidget);
    });

    testWidgets('异常经期：可选 20 天（不再被 7 天上限卡住）', (tester) async {
      // 起点取 25 天前，保证 20 天结束日仍在今天之前
      final longStart = today.subtract(const Duration(days: 25));
      await pumpCalendar(tester);
      await openEndPicker(tester, longStart);

      final end = longStart.add(const Duration(days: 19)); // 20 天
      await pickDay(tester, longStart, end);

      expect(find.textContaining('共 20 天'), findsOneWidget);
      await tester.tap(find.textContaining('补记 ${longStart.month}月${longStart.day}日 – '));
      await tester.pumpAndSettle();

      final rows = await db.select(db.periodCycles).get();
      expect(rows, hasLength(1));
      expect(rows.single.periodLength, 20);
    });

    testWidgets('今天这一天才提供“只记开始日”', (tester) async {
      await pumpCalendar(tester);

      await tester.tap(dayCell(today.day));
      await tester.pumpAndSettle();

      expect(find.text('只记开始日'), findsOneWidget);
    });

    testWidgets('过去的日期不提供“只记开始日”（避免历史周期一直"进行中"）', (tester) async {
      await pumpCalendar(tester);
      await tester.tap(dayCell(target.day));
      await tester.pumpAndSettle();

      expect(find.text('只记开始日'), findsNothing);
    });

    testWidgets('未来的日期不提供补记入口', (tester) async {
      final tomorrow = today.add(const Duration(days: 1));
      if (tomorrow.month != today.month) return;

      await pumpCalendar(tester);
      await tester.tap(dayCell(tomorrow.day));
      await tester.pumpAndSettle();

      expect(find.text('补记经期'), findsOneWidget);
      expect(find.textContaining('这一天还没到，不能补记'), findsOneWidget);
      expect(find.textContaining('来经期，选择结束日'), findsNothing);
    });
  });
  group('已有经期的操作', () {
    testWidgets('点经期内的一天 → 出现改结束日与删除', (tester) async {
      final start = target.subtract(const Duration(days: 2));
      // 进行中的经期：该日仍可「经期到这天结束」
      await repo.upsertHistoricalPeriod(start: start);

      await pumpCalendar(tester);
      await tester.tap(dayCell(target.day));
      await tester.pumpAndSettle();

      expect(find.textContaining('这段经期：'), findsOneWidget);
      expect(find.text('经期到这天结束'), findsOneWidget);
      expect(find.text('删除这段经期'), findsOneWidget);
      expect(find.text('补记经期'), findsNothing);
    });

    testWidgets('删除需要二次确认，确认后数据消失', (tester) async {
      final start = target.subtract(const Duration(days: 2));
      await repo.upsertHistoricalPeriod(start: start, end: target);

      await pumpCalendar(tester);
      await tester.tap(dayCell(target.day));
      await tester.pumpAndSettle();

      await tester.tap(find.text('删除这段经期'));
      await tester.pumpAndSettle();

      expect(find.text('删除这段经期？'), findsOneWidget);
      // 先取消：数据应还在
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect((await db.select(db.periodCycles).get()), hasLength(1));

      // 取消后弹层仍在，直接再点一次删除并确认
      await tester.tap(find.text('删除这段经期'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      expect(await db.select(db.periodCycles).get(), isEmpty);
      expect(find.textContaining('已删除'), findsOneWidget);
    });
  });

  group('逐日记录与撤销结束日（P4-2）', () {
    testWidgets('点经量「少」→ 写入该日记录', (tester) async {
      final start = target.subtract(const Duration(days: 2));
      await repo.upsertHistoricalPeriod(start: start, end: target);

      await pumpCalendar(tester);
      await tester.tap(dayCell(target.day));
      await tester.pumpAndSettle();

      expect(find.text('这天经量'), findsOneWidget);
      await tester.ensureVisible(find.text('少'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('少'));
      await tester.pumpAndSettle();

      final record = await repo.recordOf(target);
      expect(record?.flowLevel, 1); // FlowLevel.light
    });

    testWidgets('点痛经「明显」→ 写入该日记录', (tester) async {
      final start = target.subtract(const Duration(days: 2));
      await repo.upsertHistoricalPeriod(start: start, end: target);

      await pumpCalendar(tester);
      await tester.tap(dayCell(target.day));
      await tester.pumpAndSettle();

      expect(find.text('这天痛经'), findsOneWidget);
      await tester.ensureVisible(find.text('明显'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('明显'));
      await tester.pumpAndSettle();

      final record = await repo.recordOf(target);
      expect(record?.painLevel, 2); // PainLevel.moderate
    });

    testWidgets('已结束的经期可撤销结束日（回到进行中）', (tester) async {
      final start = target.subtract(const Duration(days: 4));
      await repo.upsertHistoricalPeriod(start: start, end: target);

      await pumpCalendar(tester);
      await tester.tap(dayCell(target.day));
      await tester.pumpAndSettle();

      expect(find.text('撤销结束日'), findsOneWidget);
      await tester.ensureVisible(find.text('撤销结束日'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('撤销结束日'));
      await tester.pumpAndSettle();

      final rows = await db.select(db.periodCycles).get();
      expect(rows.single.endDate, isNull);
      expect(find.textContaining('已撤销结束日'), findsOneWidget);
    });
  });
}



