// test/period/period_history_page_test.dart
//
// P5-2「经期历史」验收：
//   · 无记录 → 空态引导
//   · 有记录 → 顶部统计（次数 / 平均周期 / 平均经期）与年分组正确
//   · 删除需要二次确认，删除后列表与库同步减少
//
// 统计口径：平均周期只用「有 cycleLength 的段」——进行中那段没有长度，
// 算进去会把平均值拉低，这与预测服务的口径必须一致。

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';
import 'package:cycle_note/features/period/data/period_repository.dart';
import 'package:cycle_note/features/period/pages/period_history_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PeriodRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PeriodRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const PeriodHistoryPage(),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  Future<void> seed() async {
    await repo.upsertHistoricalPeriod(
      start: DateTime(2026, 8, 1),
      end: DateTime(2026, 8, 5),
    );
    await repo.upsertHistoricalPeriod(
      start: DateTime(2026, 8, 29),
      end: DateTime(2026, 9, 2),
    );
    await repo.upsertHistoricalPeriod(
      start: DateTime(2026, 9, 26),
      end: DateTime(2026, 9, 30),
    );
  }

  testWidgets('无记录 → 空态引导', (tester) async {
    await pump(tester);
    expect(find.text('还没有经期记录'), findsOneWidget);
  });

  testWidgets('有记录 → 统计与年分组正确', (tester) async {
    await seed();
    await pump(tester);

    expect(find.text('记录次数'), findsOneWidget);
    expect(find.text('平均周期'), findsOneWidget);
    expect(find.text('平均经期'), findsOneWidget);

    // 3 段、平均周期 28.0（只有前两段有长度）、平均经期 5.0
    expect(find.text('28.0'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);

    expect(find.text('2026 年 · 3 次'), findsOneWidget);
    // 倒序：9 月那段排在最前
    expect(find.text('9月26日 – 9月30日'), findsOneWidget);
    expect(find.text('8月1日 – 8月5日'), findsOneWidget);
  });

  testWidgets('删除需二次确认，确认后列表与库同步', (tester) async {
    await seed();
    await pump(tester);

    await tester.tap(find.byTooltip('删除这段').first);
    await tester.pumpAndSettle();

    expect(find.text('删除这段经期？'), findsOneWidget);
    // 先取消
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(await db.select(db.periodCycles).get(), hasLength(3));

    // 再删并确认
    await tester.tap(find.byTooltip('删除这段').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(await db.select(db.periodCycles).get(), hasLength(2));
    expect(find.text('2026 年 · 2 次'), findsOneWidget);
    expect(find.textContaining('已删除'), findsOneWidget);
  });
}
