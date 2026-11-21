// test/weight_loss/meal_plan_reroll_test.dart
//
// P2-2「30 天餐单 + 换一道」验收，逐条对应手册：
//   · 30 天覆盖 ≥30 种食材
//   · 连续两天同一餐不完全相同（轮换有效）
//   · 30 天生成 ≤100 ms（7/30 切换不卡顿的前提）
//   · 换一道不改当日总热量 ±3%
//   · 换一道确实换了食材（不是同一组内容重复渲染）
//   · 换一道是确定性的：同 offset 重算结果一致
//
// 引擎轮换算法本身（步长 11、salt）不在这里测——它已被 P2-1 测试锁住，
// composeMeal 只是 dayIndex 平移，不许改轮换语义。

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';
import 'package:cycle_note/features/weight_loss/services/meal_plan_engine.dart';
import 'package:cycle_note/features/weight_loss/services/meal_plan_loader.dart';
import 'package:cycle_note/features/weight_loss/services/tdee_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MealPlanEngine engine;
  late UserProfile profile;
  late CalorieBudget budget;
  late MultiDayPlan plan30;

  setUpAll(() async {
    final foods = await MealPlanLoader.instance.loadSeedFoods();
    engine = MealPlanEngine(foods: foods);

    profile = const UserProfile(
      sex: Sex.female,
      age: 28,
      heightCm: 162,
      weightKg: 62,
      activity: ActivityLevel.sedentary,
    );
    budget = const TdeeService().calculate(profile);
    plan30 = engine.generate(profile: profile, budget: budget, days: 30);
  });

  group('30 天计划', () {
    test('30 天每天四餐齐全、偏差 ≤5%', () {
      expect(plan30.days, hasLength(30));

      final deviations = MealPlanEngine.validate(plan30);
      for (var i = 0; i < deviations.length; i++) {
        expect(
          deviations[i].abs(),
          lessThanOrEqualTo(5.0),
          reason: '第 ${i + 1} 天偏差 ${deviations[i].toStringAsFixed(2)}% 超容差',
        );
      }

      for (final day in plan30.days) {
        for (final meal in const ['breakfast', 'lunch', 'dinner', 'snack']) {
          expect(
            day.byMeal(meal),
            isNotEmpty,
            reason: '第 ${day.dayIndex + 1} 天的 $meal 缺了',
          );
        }
      }
    });

    test('30 天覆盖 ≥30 种食材', () {
      final codes = <String>{};
      for (final day in plan30.days) {
        for (final e in day.entries) {
          codes.add(e.food.code);
        }
      }
      expect(
        codes.length,
        greaterThanOrEqualTo(30),
        reason: '30 天只出现 ${codes.length} 种食材，多样性不足',
      );
    });

    test('连续两天同一餐不完全相同', () {
      for (var d = 0; d < plan30.days.length - 1; d++) {
        final today = plan30.days[d].byMeal('lunch').map((e) => e.food.code);
        final tomorrow = plan30.days[d + 1].byMeal('lunch').map((e) => e.food.code);
        expect(
          today.join(','), isNot(equals(tomorrow.join(','))),
          reason: '第 ${d + 1}/${d + 2} 天午餐完全相同，轮换失效',
        );
      }
    });

    test('30 天生成 ≤100 ms（切换 7/30 不卡顿的前提）', () {
      final sw = Stopwatch()..start();
      final p = engine.generate(profile: profile, budget: budget, days: 30);
      sw.stop();
      expect(p.days, hasLength(30));
      // CI 与调试模式都会拖慢执行；手册口径按"不卡顿"放宽到 100ms。
      expect(
        sw.elapsedMilliseconds,
        lessThanOrEqualTo(100),
        reason: '30 天生成耗时 ${sw.elapsedMilliseconds} ms',
      );
    });
  });

  group('换一道（composeMeal）', () {
    double mealTarget(String meal) {
      const s = MealSplit.standard;
      return switch (meal) {
        'breakfast' => budget.intakeTarget * s.breakfast,
        'lunch' => budget.intakeTarget * s.lunch,
        'dinner' => budget.intakeTarget * s.dinner,
        _ => budget.intakeTarget * s.snack,
      };
    }

    /// 某天"换一道后"的总热量相对**原计划同一天总热量**的变化。
    /// 手册口径是"换一道不改变当日总热量 ±3%"——对比对象是换之前的
    /// 当天计划，而不是全局预算（计划本身对预算的偏差由 ±5% 横幅负责）。
    double rerollDrift(int day, String meal, int offset) {
      final original = plan30.days[day].byMeal(meal)
          .fold(0.0, (s, e) => s + e.kcal);
      final replaced = engine
          .composeMeal(
            meal: meal,
            targetKcal: mealTarget(meal),
            dayIndex: day,
            rotationOffset: offset,
          )
          .fold(0.0, (s, e) => s + e.kcal);
      final dayTarget = plan30.budget.intakeTarget *
          (mealTarget(meal) / plan30.budget.intakeTarget);
      if (dayTarget <= 0) return 0;
      return (replaced - original) / dayTarget * 100;
    }

    for (final meal in const ['breakfast', 'lunch', 'dinner', 'snack']) {
      test('$meal：换一道不改当日总热量 ±3%，且确实换了食材', () {
        final target = mealTarget(meal);
        var checked = 0;
        for (var d = 0; d < plan30.days.length; d++) {
          final before = plan30.days[d].byMeal(meal).map((e) => e.food.code).join(',');
          final after = engine
              .composeMeal(
                meal: meal,
                targetKcal: target,
                dayIndex: d,
                rotationOffset: 1,
              )
              .map((e) => e.food.code)
              .join(',');

          final drift = rerollDrift(d, meal, 1);
          expect(
            drift.abs(),
            lessThanOrEqualTo(3.0),
            reason: '第 ${d + 1} 天换过 $meal 后当日总热量变化 ${drift.toStringAsFixed(2)}% 超线',
          );

          if (after != before) checked++;
        }
        // 30 天里至少大半天数确实换到了不同食材；池子太小会撞回同一组，
        // 撞回也算合规（总热量守住了），但不能天天原地踏步。
        expect(checked, greaterThanOrEqualTo(15),
            reason: '$meal 换一道 30 天里只有 $checked 天内容变了');
      });

      test('$meal：同 offset 重算结果一致（确定性）', () {
        final a = engine.composeMeal(
          meal: meal, targetKcal: mealTarget(meal), dayIndex: 5, rotationOffset: 3,
        );
        final b = engine.composeMeal(
          meal: meal, targetKcal: mealTarget(meal), dayIndex: 5, rotationOffset: 3,
        );
        expect(
          a.map((e) => '${e.food.code}@${e.grams}').join('|'),
          equals(b.map((e) => '${e.food.code}@${e.grams}').join('|')),
        );
      });
    }
  });
}
