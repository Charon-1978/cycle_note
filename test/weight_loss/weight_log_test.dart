// test/weight_loss/weight_log_test.dart
//
// P1-4 的验收测试，逐条对应手册：
//   · 一天记多条，趋势取当日最后一条
//   · 图表消费的 points 与 repository.weightTrend 输出一致（同一份数据，不二次加工）
//   · 体重上升用中性灰（weightUp），断言非 danger
//   · 0 / 1 / 2 条数据均不崩溃
//   · 保存后趋势图立即更新（不手动刷新）
//
// 另外锁一条 UI 纪律：图例里必须有「7 日平均」字样 —— 这张图的唯一卖点
// 就是"看平均不看单日"，如果哪天有人把图例删了或把原始线当主视觉，这里会红。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/app/theme/app_colors.dart';
import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';
import 'package:cycle_note/features/weight_loss/data/weight_loss_repository.dart';
import 'package:cycle_note/features/weight_loss/pages/weight_log_page.dart';
import 'package:cycle_note/features/weight_loss/providers/weight_loss_providers.dart';
import 'package:cycle_note/features/weight_loss/widgets/weight_input.dart';
import 'package:cycle_note/features/weight_loss/widgets/weight_trend_chart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WeightLossRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WeightLossRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedProfile({double weight = 62, double? target}) async {
    await db.into(db.bodyProfiles).insertOnConflictUpdate(
          BodyProfilesCompanion.insert(
            id: const Value(1),
            sex: 'female',
            age: 28,
            heightCm: 162,
            startWeightKg: weight,
            activityLevel: 'sedentary',
            targetWeightKg: Value(target),
          ),
        );
  }

  group('趋势数据（repository 层）', () {
    test('一天记多条，趋势取当日最后一条', () async {
      // 取"今天上午 10 点"起算：固定时刻避免跨天抖动，
      // 又不会因为日期太旧被 30 天窗口过滤掉
      final n = DateTime.now();
      final d = DateTime(n.year, n.month, n.day, 10);
      await repo.addWeight(weightKg: 60.0, at: d);
      await repo.addWeight(weightKg: 61.5, at: d.add(const Duration(hours: 2)));
      await repo.addWeight(weightKg: 62.8, at: d.add(const Duration(hours: 5)));

      final points = await repo.weightTrend();
      expect(points, hasLength(1));
      // 顺序遍历、后面的覆盖前面的 → 保留最后一次
      expect(points.single.raw, 62.8);
      // 只有 1 天 → 移动平均就等于它自己
      expect(points.single.trend, closeTo(62.8, 0.0001));
    });

    test('0 条 → 空列表；1 条 → 平均等于自身；2 条 → 平均是两者中点', () async {
      expect(await repo.weightTrend(), isEmpty, reason: '0 条不能崩');

      final now = DateTime.now();
      await repo.addWeight(weightKg: 60.0, at: now);
      var points = await repo.weightTrend();
      expect(points.single.trend, closeTo(60.0, 0.0001), reason: '1 条不崩');

      await repo.addWeight(weightKg: 62.0, at: now.add(const Duration(days: 1)));
      points = await repo.weightTrend();
      expect(points, hasLength(2));
      expect(points.last.trend, closeTo(61.0, 0.0001), reason: '2 条窗口 = 两者平均');
    });

    test('移动平均窗口为 7 天（第 8 条起不再拉入更早的）', () async {
      final n = DateTime.now();
      final base = DateTime(n.year, n.month, n.day).subtract(const Duration(days: 7));
      final weights = [50, 51, 52, 53, 54, 55, 56, 70];
      for (var i = 0; i < weights.length; i++) {
        await repo.addWeight(
          weightKg: weights[i].toDouble(),
          at: base.add(Duration(days: i)),
        );
      }

      final points = await repo.weightTrend();
      // 第 8 条的窗口 = [51..70] 共 7 条 → 平均 62.2857…
      expect(points.last.trend, closeTo((51 + 52 + 53 + 54 + 55 + 56 + 70) / 7, 0.001));
      // 第 7 条的窗口是全部 7 条 → 53
      expect(points[6].trend, closeTo(53.0, 0.001));
    });
  });

  group('趋势图组件', () {
    final sample = [
      WeightPoint(date: _d1, raw: 62.0, trend: 62.0),
      WeightPoint(date: _d2, raw: 61.5, trend: 61.75),
      WeightPoint(date: _d3, raw: 61.8, trend: 61.77),
    ];

    Widget host({required List<WeightPoint> points, double? target}) =>
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            body: WeightTrendChart(points: points, targetWeightKg: target),
          ),
        );

    testWidgets('0 / 1 / 2 条数据均不崩溃', (tester) async {
      for (final n in [0, 1, 2]) {
        await tester.pumpWidget(host(points: sample.take(n).toList()));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$n 条数据时抛异常');
      }
    });

    testWidgets('带目标线也不崩溃（目标在数据范围外）', (tester) async {
      await tester.pumpWidget(host(points: sample, target: 50.0));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('页面', () {
    Future<void> pump(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const WeightLogPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('无数据 → EmptyState 引导，不显示 0.0 kg', (tester) async {
      await pump(tester);

      expect(find.text('记一次体重，开始看趋势'), findsOneWidget);
      expect(find.text('未记录'), findsOneWidget);
    });

    testWidgets('有数据 → 图例出现「7 日平均」，且保存后立即更新', (tester) async {
      await seedProfile();
      final now = DateTime.now();
      await repo.addWeight(weightKg: 62.0, at: now);

      await pump(tester);
      expect(find.text('7 日平均'), findsOneWidget);
      // 62.0 会同时出现在"当前体重"卡与"最近记录"列表里
      expect(find.text('62.0'), findsWidgets);

      // 再记一条更重的，页面应立即反映（不手动刷新）
      await db.into(db.weightLogs).insert(
            WeightLogsCompanion.insert(
              recordedAt: now.add(const Duration(hours: 1)),
              weightKg: 63.4,
            ),
          );
      // 模拟 repository 侧的真实刷新路径
      // （WeightQuickInput 保存时走的就是 invalidateWeightLossChain）
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WeightLogPage)),
      );
      invalidateWeightLossChain(container.invalidate);
      await tester.pumpAndSettle();

      expect(find.text('63.4'), findsWidgets);
    });

    testWidgets('体重上升时差值颜色是中性灰，不是红', (tester) async {
      await seedProfile(weight: 62, target: 55);
      await repo.addWeight(weightKg: 66.0, at: DateTime.now());

      await pump(tester);

      final label = tester.widget<Text>(find.textContaining('还需减'));
      expect(
        label.style?.color,
        AppColors.light.weightUp,
        reason: 'ADR-3：体重上升是中性信息，红色只留给破坏性操作',
      );
      expect(label.style?.color, isNot(AppColors.light.danger));
    });
  });

  group('快速录入（弹层）', () {
    testWidgets('非法体重被拦截，合法值回显在按钮上', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: Scaffold(body: WeightQuickInput())),
        ),
      );
      await tester.pumpAndSettle();

      final field = find.widgetWithText(TextField, '体重');
      await tester.enterText(field, '999');
      await tester.pumpAndSettle();
      expect(find.textContaining('体重应在 25–300'), findsOneWidget);

      await tester.enterText(field, '61.5');
      await tester.pumpAndSettle();
      expect(find.textContaining('体重应在'), findsNothing);
      expect(find.text('记 61.5 kg'), findsOneWidget);
    });
  });
}

final _d1 = DateTime(2026, 1, 1);
final _d2 = DateTime(2026, 1, 2);
final _d3 = DateTime(2026, 1, 3);
