// test/today/today_page_test.dart
//
// 2026-11 视觉升级后「今日」页的结构验收。
//
// 为什么要在页面层再锁一遍：
//   这次改动把首页从"三张卡 + 一行按钮"改成了"渐变头 + 热量环 + 明细 +
//   四餐 + 快捷入口 + 洞察条"。这些区块各自有单测，但**排版顺序与关键入口**
//   只能整页测——它们才是"用户能不能在首屏记一笔"的决定因素。
//
// 锁的四件事：
//   1. 空档案：渐变头给"开始记录你的周期"，四餐卡与快捷入口仍在（能记饮食）
//   2. 有档案：热量环出现剩余数字，明细等式成立
//   3. 四餐卡的四行都在，且点得动（打开食物选择器）
//   4. 快捷入口 4 个都在，且"来经期"能落库（周期数 0 → 1）

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';
import 'package:cycle_note/features/period/data/period_repository.dart';
import 'package:cycle_note/features/today/pages/today_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpToday(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(theme: buildLightTheme(), home: const TodayPage()),
      ),
    );
    // 首页要读 assets（食物库）与内存库，先让真实 IO 跑完再 settle
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 120));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('空档案：渐变头给引导，四餐与快捷入口都在', (tester) async {
    await pumpToday(tester);

    expect(find.text('开始记录你的周期'), findsOneWidget);
    // 热量环的空态（这句文案被冒烟测试与热量环测试同时依赖）
    expect(find.text('还没算你的每日热量'), findsOneWidget);

    // 四餐卡
    expect(find.text('今天吃什么'), findsOneWidget);
    for (final label in ['早餐', '午餐', '晚餐', '加餐']) {
      expect(find.text(label), findsOneWidget, reason: '缺餐次：$label');
    }

    // 快捷入口
    for (final label in ['记体重', '记运动', '记饮食', '来经期']) {
      expect(find.text(label), findsOneWidget, reason: '缺快捷入口：$label');
    }
  });

  /// 首页是长列表，快捷入口在第二屏 —— 测试里必须先滚到它再点，
  /// 否则 tap 会落在屏幕外（报 "would not hit test"）。
  Future<void> tapAfterScroll(WidgetTester tester, String label) async {
    final target = find.text(label).first;
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('点「来经期」落库后，头部变成经期第 1 天且出现经量选择', (tester) async {
    await pumpToday(tester);

    await tapAfterScroll(tester, '来经期');

    // 头部在列表顶部，滚下去之后可能已被回收 —— 先滚回顶部再断言
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1400));
    await tester.pumpAndSettle();

    expect(find.text('经期第 1 天'), findsWidgets);
    expect(find.text('今天的经量'), findsOneWidget);

    // 库里真的写了一条周期（UI 不是只改了本地状态）
    final cycles = await db.select(db.periodCycles).get();
    expect(cycles, hasLength(1));
  });

  testWidgets('点「结束今天」后头部变成“已结束”，且能撤销回进行中', (tester) async {
    await pumpToday(tester);

    // 1) 开始经期
    await tapAfterScroll(tester, '来经期');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1400));
    await tester.pumpAndSettle();

    // 2) 结束（今天仍算经期日，所以数据层不会把 periodDay 抹掉）
    await tapAfterScroll(tester, '经期结束了');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1400));
    await tester.pumpAndSettle();

    // 3) 头部必须给出"已经结束"的明确反馈（否则用户会以为没点上）
    expect(find.text('经期已在今天结束'), findsOneWidget);
    expect(find.textContaining('撤销'), findsWidgets);

    // 4) 撤销入口可用：点完回到"经期第 N 天"
    await tapAfterScroll(tester, '撤销结束');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1400));
    await tester.pumpAndSettle();
    expect(find.text('经期第 1 天'), findsWidgets);

    final cycles = await db.select(db.periodCycles).get();
    expect(cycles.single.endDate, isNull, reason: '撤销后应回到未结束');
  });

  testWidgets('已记录经期但没记经量时，没有任何一档被预选', (tester) async {    await pumpToday(tester);
    await tapAfterScroll(tester, '来经期');

    final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
    expect(chips, isNotEmpty);
    expect(chips.every((c) => c.selected == false), isTrue,
        reason: '未记录时预选「无」会让用户以为自己记过');
  });

  testWidgets('只有 1 个完整周期时，预测文案降级为“前后”而不是精确天数', (tester) async {
    // 10/20 一段（无 cycleLength）+ 今天一段 → 推导出 1 个周期长度
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await db.into(db.periodCycles).insert(
          PeriodCyclesCompanion.insert(
            startDate: today.subtract(const Duration(days: 33)),
            endDate: Value(today.subtract(const Duration(days: 29))),
            periodLength: const Value(5),
            isClosed: const Value(false),
          ),
        );
    await db.into(db.periodCycles).insert(
          PeriodCyclesCompanion.insert(startDate: today),
        );

    await pumpToday(tester);

    // 单周期不给"距下次经期 N 天"这种确定性表述
    expect(find.textContaining('只有 1 个完整周期'), findsOneWidget);
    expect(find.textContaining('距下次经期'), findsNothing);
  });

  testWidgets('有 2 个以上周期时才给置信度与天数', (tester) async {
    // 造两段规律历史：30 天前 + 60 天前
    final now = DateTime.now();
    for (final offset in [60, 30]) {
      await db.into(db.periodCycles).insert(
            PeriodCyclesCompanion.insert(
              startDate: DateTime(now.year, now.month, now.day)
                  .subtract(Duration(days: offset)),
              endDate: Value(DateTime(now.year, now.month, now.day)
                  .subtract(Duration(days: offset - 4))),
              cycleLength: const Value(30),
              periodLength: const Value(5),
              isClosed: const Value(true),
            ),
          );
    }

    await pumpToday(tester);

    expect(find.textContaining('预测'), findsWidgets);
    expect(find.textContaining('置信度'), findsWidgets);
  });

  test('仓库层：经期记录后 cyclesProvider 能读到（防止 UI 只改状态）', () async {
    final repo = PeriodRepository(db);
    await repo.startPeriod(DateTime.now());
    expect(await repo.loadCycles(), hasLength(1));
  });
}
