// test/app_smoke_test.dart
//
// 冒烟测试：整个 App 能不能起来、四个 Tab 能不能切、今日页的两张卡会不会炸。
//
// 为什么值得单独写一条：
//   Provider 之间的依赖是编译期查不出来的。这一轮把 todayEnergyProvider
//   从 FutureProvider 改成了「Provider<AsyncValue<...>> 包着 family」，
//   编译通过、单测全绿，但只有真正把 App 装配起来跑一遍，
//   才能确认没有 provider 循环依赖 / 类型错配 / 无限重建。

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/app/app.dart';
import 'package:cycle_note/app/providers.dart';
import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPrefsProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const CycleNoteApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('启动即落在「今日」，四个 Tab 都在', (tester) async {
    await pumpApp(tester);

    expect(find.text('今日'), findsWidgets);
    expect(find.text('日历'), findsOneWidget);
    expect(find.text('趋势'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    // 今日页的两张卡都应渲染出来（没有档案 → 两张都是空态/不渲染）
    expect(find.text('还没算你的每日热量'), findsOneWidget);
    expect(find.text('今日明细'), findsNothing);
  });

  testWidgets('四个 Tab 都能切换且不抛异常', (tester) async {
    await pumpApp(tester);

    for (final label in ['日历', '趋势', '我的', '今日']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '切到「$label」时抛异常');
    }
  });

  testWidgets('从「我的」进入身体档案页', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('我的').last);
    await tester.pumpAndSettle();

    expect(find.text('身体档案'), findsOneWidget);
    await tester.tap(find.text('身体档案'));
    await tester.pumpAndSettle();

    // 档案页有"保存"按钮和结果区标题
    expect(find.text('保存'), findsOneWidget);
    expect(find.text('基础信息'), findsOneWidget);
  });
}
