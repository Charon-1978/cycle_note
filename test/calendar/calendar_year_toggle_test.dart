// test/calendar/calendar_year_toggle_test.dart
//
// 日历页「月 / 年」切换的验收（计划书 §4.2 年视图）：
//   · 默认是月视图（MonthGrid 在）；
//   · 点右上角切换到年视图（12 个月全在，MonthGrid 不在）；
//   · 在年视图里点某个月 → 回到月视图且停在该月；
//   · 年视图下左右箭头按"年"翻（不是按月翻）。

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

  testWidgets('默认月视图；切到年视图后 12 个月都在，月网格消失', (tester) async {
    await pumpCalendar(tester);

    expect(find.byType(MonthGrid), findsOneWidget);
    expect(find.byType(YearOverview), findsNothing);

    await tester.tap(find.byTooltip('看全年'));
    await tester.pumpAndSettle();

    expect(find.byType(YearOverview), findsOneWidget);
    expect(find.byType(MonthGrid), findsNothing);
    for (var m = 1; m <= 12; m++) {
      expect(find.text('$m 月'), findsOneWidget);
    }
  });

  testWidgets('年视图里点某个月 → 回到月视图并停在该月', (tester) async {
    await pumpCalendar(tester);
    await tester.tap(find.byTooltip('看全年'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('3 月'));
    await tester.pumpAndSettle();

    expect(find.byType(MonthGrid), findsOneWidget);
    expect(find.byType(YearOverview), findsNothing);
    // 标题里的月份跟着变
    final now = DateTime.now();
    expect(find.textContaining('${now.year} 年 3 月'), findsOneWidget);
  });

  testWidgets('年视图下左右箭头按年翻', (tester) async {
    await pumpCalendar(tester);
    await tester.tap(find.byTooltip('看全年'));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    await tester.tap(find.byTooltip('下个月'));
    await tester.pumpAndSettle();

    // 按年翻：标题年份 +1；年视图下标题只写年份（不写月份）。
    // 注意年视图里"YYYY 年"会出现两处（标题 + 概览右下角），所以用 findsWidgets。
    expect(find.text('${now.year + 1} 年'), findsWidgets);    expect(find.textContaining('${now.year + 1} 年 ${now.month} 月'), findsNothing);
  });
}
