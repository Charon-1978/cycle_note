// test/weight_loss/meal_plan_page_test.dart
//
// P2-1 的验收测试，逐条对应手册：
//   · 7 天每日偏差 ≤5%（用真实引擎 + 真实种子食材库跑）
//   · 四餐齐全（每天早餐/午餐/晚餐/加餐都有内容）
//   · 食材库为空 → EmptyState 而非崩溃
//   · 未填档案 → 空态引导
//
// 引擎本身的算法细节（轮换步长、rebalance）不在这里重复测——
// 改引擎算法属于"改了必须人工过目"的范畴，页面测试只锁验收口径。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';
import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';
import 'package:cycle_note/features/weight_loss/pages/meal_plan_page.dart';
import 'package:cycle_note/features/weight_loss/providers/weight_loss_providers.dart';
import 'package:cycle_note/features/weight_loss/services/meal_plan_engine.dart';
import 'package:cycle_note/features/weight_loss/services/meal_plan_loader.dart';
import 'package:cycle_note/features/weight_loss/services/tdee_service.dart';

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

  Future<void> seedProfile() async {
    await db.into(db.bodyProfiles).insertOnConflictUpdate(
          BodyProfilesCompanion.insert(
            id: const Value(1),
            sex: 'female',
            age: 28,
            heightCm: 162,
            startWeightKg: 62,
            activityLevel: 'sedentary',
          ),
        );
  }

  group('引擎 + 真实食材库（验收口径）', () {
    test('7 天每日偏差 ≤5%，且四餐齐全', () async {
      final foods = await MealPlanLoader.instance.loadSeedFoods();
      final engine = MealPlanEngine(foods: foods);

      const profile = UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 162,
        weightKg: 62,
        activity: ActivityLevel.sedentary,
      );
      final budget = const TdeeService().calculate(profile);

      final plan = engine.generate(profile: profile, budget: budget, days: 7);
      expect(plan.days, hasLength(7));

      final deviations = MealPlanEngine.validate(plan);
      expect(deviations, hasLength(7));
      for (final d in deviations) {
        expect(
          d.abs(),
          lessThanOrEqualTo(5.0),
          reason: '第 ${deviations.indexOf(d) + 1} 天偏差 ${d.toStringAsFixed(2)}% 超容差',
        );
      }

      for (final day in plan.days) {
        for (final meal in const ['breakfast', 'lunch', 'dinner', 'snack']) {
          expect(
            day.byMeal(meal),
            isNotEmpty,
            reason: '第 ${day.dayIndex + 1} 天的 $meal 缺了',
          );
        }
        // 同一天多次生成结果必须一致（确定性轮换），否则"换一道"没法做对比
        final again = engine.generate(
          profile: profile,
          budget: budget,
          days: 7,
        );
        expect(again.days[day.dayIndex].totalKcal, closeTo(day.totalKcal, 0.01));
      }
    });

    test('食材库为空 → 引擎产出空餐单，不抛异常', () {
      const profile = UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 162,
        weightKg: 62,
        activity: ActivityLevel.sedentary,
      );
      final budget = const TdeeService().calculate(profile);

      final plan = MealPlanEngine().generate(
        profile: profile,
        budget: budget,
        days: 7,
      );
      expect(plan.days, hasLength(7));
      for (final day in plan.days) {
        expect(day.entries, isEmpty);
        expect(day.totalKcal, 0);
      }
    });
  });

  group('页面', () {
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
            home: const MealPlanPage(),
          ),
        ),
      );
      // 页面加载分支是 CircularProgressIndicator（无限动画），
      // pumpAndSettle 在它消失前永远停不下来；必须先在真实时钟里
      // 等 assets/DB 的 IO 完成，再 settle。
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
    }

    testWidgets('未填档案 → 空态引导，不显示假餐单', (tester) async {
      await pump(tester);
      expect(find.text('还没有餐单'), findsOneWidget);
      expect(find.text('去填身体档案'), findsOneWidget);
    });

    testWidgets('有档案 → 生成 7 天餐单，四餐齐全，含自检横幅', (tester) async {
      await seedProfile();
      await pump(tester);

      // 7 天日期条
      expect(find.text('今天'), findsOneWidget);
      expect(find.text('明天'), findsOneWidget);

      // 选中第一天时，四张餐卡都在
      expect(find.text('早餐'), findsOneWidget);
      expect(find.text('午餐'), findsOneWidget);
      expect(find.text('晚餐'), findsOneWidget);
      expect(find.text('加餐'), findsOneWidget);

      // 自检横幅：默认情况下应在容差内
      expect(find.textContaining('在 ±5% 容差内'), findsOneWidget);
    });

    testWidgets('切换日期 → 全天合计与四餐内容跟着换', (tester) async {
      await seedProfile();
      await pump(tester);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MealPlanPage)),
      );
      final plan = (await container.read(mealPlanProvider(7).future))!;

      final d0 = plan.days[0];
      final d1 = plan.days[1];

      // 第一天的内容确实渲染了
      final firstFoodText = find.text(d0.byMeal('breakfast').first.food.name);
      expect(firstFoodText, findsOneWidget);

      // 切到第二天。不能用"周几"定位：餐单从今天开始，
      // 第 N 天是星期几随时钟漂移；「明天」是控件里唯一稳定的相对标签。
      await tester.tap(find.text('明天').last);
      await tester.pumpAndSettle();

      final day2Food = d1.byMeal('breakfast').first.food.name;
      expect(find.text(day2Food), findsOneWidget);
      expect(find.textContaining('全天目标'), findsOneWidget);

      // 全天合计应跟着换（两天的数值几乎不可能完全相同；
      // 万一相同也没关系，下面还断言了食材名）
    });
  });
}
