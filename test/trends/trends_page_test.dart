// test/trends/trends_page_test.dart
//
// P2-4「趋势页统一」验收，逐条对应手册：
//   · 三图切换（周期/体重/热量），共用通用 TrendLineChart
//   · 无数据 → 空态引导，不崩
//   · 单点体重 → 画标记不崩，摘要提示"再记录几天"
//   · 极值体重（30kg / 250kg 级别）→ 图不崩
//   · 每图带文字摘要（TrendSummary 文本可查 + Semantics）
//
// 时钟纪律：所有种子日期相对 now 构造，避免跨天/30 天窗口漂移。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';
import 'package:cycle_note/features/trends/pages/trends_page.dart';
import 'package:cycle_note/features/trends/widgets/trend_line_chart.dart';

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

  DateTime today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> seedWeights(List<double> kg, {int spacedDays = 1}) async {
    final t = today();
    for (var i = 0; i < kg.length; i++) {
      await db.into(db.weightLogs).insert(
            WeightLogsCompanion.insert(
              recordedAt: t.subtract(Duration(days: (kg.length - 1 - i) * spacedDays)),
              weightKg: kg[i],
            ),
          );
    }
  }

  Future<void> seedCycles() async {
    final t = today();
    // 三个完整周期，长度 28/29/30（起点从旧到新）
    final starts = [
      t.subtract(const Duration(days: 87)),
      t.subtract(const Duration(days: 59)),
      t.subtract(const Duration(days: 30)),
    ];
    for (var i = 0; i < starts.length; i++) {
      await db.into(db.periodCycles).insert(
            PeriodCyclesCompanion.insert(
              startDate: starts[i],
              endDate: Value(starts[i].add(const Duration(days: 5))),
              cycleLength: Value(i == 2 ? 30 : 28 + i),
              periodLength: Value(5),
              isClosed: Value(true),
            ),
          );
    }
  }

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: const TrendsPage(),
        ),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  Future<void> switchTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('空数据', () {
    testWidgets('三个 tab 都是空态引导，不崩', (tester) async {
      await pumpPage(tester);
      expect(find.text('周期数据还不够'), findsOneWidget);

      await switchTab(tester, '体重');
      expect(find.text('还没有体重记录'), findsOneWidget);

      await switchTab(tester, '热量');
      expect(find.text('还没有饮食或运动记录'), findsOneWidget);
    });
  });

  group('有数据', () {
    testWidgets('周期：显示长度折线与文字摘要（平均/最长/最短）', (tester) async {
      await seedCycles();
      await pumpPage(tester);

      expect(find.textContaining('共 3 个完整周期，平均 29.0 天，最长 30 天，最短 28 天'),
          findsOneWidget);
    });

    testWidgets('体重：单点不崩，摘要提示再记录几天', (tester) async {
      await seedWeights([55.0]);
      await pumpPage(tester);
      await switchTab(tester, '体重');

      expect(find.textContaining('再记录几天'), findsOneWidget);
    });

    testWidgets('体重：多点显示趋势摘要，Semantics 带图名', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await seedWeights([58.0, 57.5, 57.2, 56.8, 56.5]);
        await pumpPage(tester);
        await switchTab(tester, '体重');

        // 最新趋势值 = 最后 5 天均值 57.2，首点趋势 = 58.0 → 下降 0.8
        expect(find.textContaining('下降'), findsOneWidget);
        // Semantics：图节点要带图名，读屏用户能知道"这是什么图"
        // （不用 bySemanticsLabel：label 会与子节点合并，等值匹配不可靠）
        final node = tester.getSemantics(find.byType(TrendLineChart));
        expect(node.label, contains('体重趋势图'));
      } finally {
        // ensureSemantics 的 handle 必须在测试体内显式释放：
        // addTearDown 晚于框架的"句柄未释放"校验执行，会误报。
        semantics.dispose();
      }
    });

    testWidgets('体重：极值 250kg 也不崩', (tester) async {
      await seedWeights([249.0, 249.8, 250.0]);
      await pumpPage(tester);
      await switchTab(tester, '体重');

      // 最后一个趋势点 = 三天均值 249.6
      expect(find.textContaining('最新 249.6'), findsOneWidget);
    });

    testWidgets('热量：有记录天数与平均摄入出现在摘要里', (tester) async {
      final t = today();
      await db.into(db.mealLogs).insert(
            MealLogsCompanion.insert(
              recordedAt: t.subtract(const Duration(days: 2)),
              mealType: 'lunch',
              foodCode: 'chicken_breast',
              foodName: '鸡胸肉',
              grams: 150,
              kcal: 200,
            ),
          );
      await db.into(db.mealLogs).insert(
            MealLogsCompanion.insert(
              recordedAt: t.subtract(const Duration(days: 1)),
              mealType: 'dinner',
              foodCode: 'rice',
              foodName: '米饭',
              grams: 200,
              kcal: 232,
            ),
          );
      await pumpPage(tester);
      await switchTab(tester, '热量');

      expect(find.textContaining('有记录的 2 天平均摄入 216 kcal'), findsOneWidget);
    });
  });
}
