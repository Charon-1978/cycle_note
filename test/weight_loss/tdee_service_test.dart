// test/weight_loss/tdee_service_test.dart
//
// 锁死公式与安全边界。
//
// 为什么必须锁死数字：TdeeService 是用户唯一看到的"科学依据"，
// 系数或顺序被人"顺手优化"一下，所有人的预算都会静默变化，
// 而这种变化在 UI 上完全看不出来（只是数字不一样）。
//
// 边界顺序（calculate 的执行顺序，改顺序会改变结果）：
//   effectiveGoal → 目标缺口 → 缺口封顶 25% TDEE → 安全下限 → 营养素

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';
import 'package:cycle_note/features/weight_loss/services/tdee_service.dart';

const _svc = TdeeService();

/// 手册验收用的基准档案：女 28 岁 / 162 cm / 62 kg / 久坐 / 减脂 标准
const _baseline = UserProfile(
  sex: Sex.female,
  age: 28,
  heightCm: 162,
  weightKg: 62,
  activity: ActivityLevel.sedentary,
);

void main() {
  group('BMR', () {
    test('Mifflin-St Jeor 女性：10W + 6.25H − 5A − 161', () {
      // 10*62 + 6.25*162 - 5*28 - 161 = 1331.5
      expect(_svc.bmr(_baseline), closeTo(1331.5, 0.001));
      expect(_svc.bmrFormulaName(_baseline), 'Mifflin-St Jeor');
    });

    test('Mifflin-St Jeor 男性比女性多 166', () {
      const male = UserProfile(
        sex: Sex.male,
        age: 28,
        heightCm: 162,
        weightKg: 62,
        activity: ActivityLevel.sedentary,
      );
      expect(_svc.bmr(male) - _svc.bmr(_baseline), closeTo(166, 0.001));
    });

    test('有体脂率时切 Katch-McArdle：370 + 21.6 × 去脂体重', () {
      const p = UserProfile(
        sex: Sex.female,
        age: 28,
        heightCm: 162,
        weightKg: 62,
        activity: ActivityLevel.sedentary,
        bodyFatPercent: 25,
      );
      // 去脂体重 = 62 × 0.75 = 46.5 → 370 + 21.6×46.5 = 1374.4
      expect(_svc.bmr(p), closeTo(1374.4, 0.001));
      expect(_svc.bmrFormulaName(p), 'Katch-McArdle');
    });

    test('体脂率超出生理范围（0 或 99）时退回 Mifflin', () {
      for (final fat in [0.0, 1.0, 70.0, 99.0]) {
        final p = _baseline.copyWith(bodyFatPercent: fat);
        expect(
          _svc.bmrFormulaName(p),
          'Mifflin-St Jeor',
          reason: '体脂率 $fat% 明显是手误，不能拿它算去脂体重',
        );
      }
    });
  });

  group('缺口与安全边界', () {
    test('基准档案：缺口被 25% 上限截断，摄入被抬到 BMR', () {
      final b = _svc.calculate(_baseline);

      // TDEE = 1331.5 × 1.2 = 1597.8
      expect(b.tdee, closeTo(1597.8, 0.05));
      // 标准档 550 kcal 缺口 > 25% TDEE(399.45) → 先截到 399.45
      // 摄入 = 1198.35 < BMR 1331.5 → 再抬到 1331.5
      expect(b.intakeTarget, closeTo(1331.5, 0.05));
      expect(b.isFloored, isTrue, reason: '这个档案必须触发下限，手册拿它做验收');
      // 实际缺口 = 1597.8 − 1331.5 = 266.3
      expect(b.deficit, closeTo(266.3, 0.05));
    });

    test('缺口永远不会超过 TDEE 的 25%', () {
      for (final level in ActivityLevel.values) {
        final p = _baseline.copyWith(
          activity: level,
          pace: LossPace.aggressive,
        );
        final b = _svc.calculate(p);
        // 容差 0.1：deficit 被 _round 到 1 位小数，可能比精确上限多 0.05
        expect(
          b.deficit,
          lessThanOrEqualTo(b.tdee * 0.25 + 0.1),
          reason: '${level.name} 下缺口超了 25%',
        );
      }
    });

    test('摄入永远不低于基础代谢', () {
      for (final w in [45.0, 55.0, 65.0, 80.0, 110.0]) {
        for (final level in ActivityLevel.values) {
          final p = _baseline.copyWith(weightKg: w, activity: level);
          final b = _svc.calculate(p);
          expect(
            b.intakeTarget,
            greaterThanOrEqualTo(b.bmr - 0.05),
            reason: '体重 $w / ${level.name}：摄入低于了 BMR',
          );
        }
      }
    });

    test('女性不低于 1200，男性不低于 1500', () {
      // 极小体型 + 久坐 + 较快：必然触发绝对下限
      const tinyWoman = UserProfile(
        sex: Sex.female,
        age: 60,
        heightCm: 145,
        weightKg: 40,
        activity: ActivityLevel.sedentary,
        pace: LossPace.aggressive,
      );
      const tinyMan = UserProfile(
        sex: Sex.male,
        age: 60,
        heightCm: 145,
        weightKg: 42,
        activity: ActivityLevel.sedentary,
        pace: LossPace.aggressive,
      );

      expect(_svc.calculate(tinyWoman).intakeTarget, greaterThanOrEqualTo(1200));
      expect(_svc.calculate(tinyMan).intakeTarget, greaterThanOrEqualTo(1500));
    });

    test('维持目标：缺口为 0', () {
      final b = _svc.calculate(_baseline.copyWith(goal: WeightGoal.maintain));
      expect(b.deficit, 0);
      expect(b.intakeTarget, closeTo(b.tdee, 0.05));
      expect(b.isFloored, isFalse);
    });

    test('增重目标：每日盈余 300', () {
      // 必须显式给一个高于当前体重的目标，否则会因为
      // 「BMI 22 推出的目标体重已低于当前体重」被降级为维持（见下一条）
      final b = _svc.calculate(
        _baseline.copyWith(goal: WeightGoal.gain, targetWeightKg: 70),
      );
      expect(b.deficit, closeTo(-300, 0.05));
      expect(b.intakeTarget, closeTo(b.tdee + 300, 0.05));
    });

    test('选了增重但目标体重低于当前体重 → 降级为维持', () {
      // 默认目标体重按 BMI 22 推导：162 cm → 57.7 kg < 当前 62 kg
      final p = _baseline.copyWith(goal: WeightGoal.gain);
      expect(p.remainingKg, greaterThan(0));
      expect(p.effectiveGoal, WeightGoal.maintain);
      expect(_svc.calculate(p).deficit, 0);
    });

    test('已低于目标体重时自动降级为维持，不再制造缺口', () {
      // 目标体重 70 > 当前 62，却选了"减脂"
      final p = _baseline.copyWith(targetWeightKg: 70);
      expect(p.effectiveGoal, WeightGoal.maintain);

      final b = _svc.calculate(p);
      expect(b.deficit, 0, reason: 'BMI 已经偏低的人不该再被算热量缺口');
    });
  });

  group('三大营养素', () {
    test('三者热量之和约等于建议摄入（误差来自各自取整）', () {
      final b = _svc.calculate(_baseline);
      final sum = b.proteinG * 4 + b.fatG * 9 + b.carbG * 4;
      expect(sum, closeTo(b.intakeTarget, 1.0));
    });

    test('减脂期蛋白质按 1.8 g/kg，维持期 1.6 g/kg', () {
      final lose = _svc.calculate(_baseline);
      expect(lose.proteinG, closeTo(1.8 * 62, 0.05));

      final maintain =
          _svc.calculate(_baseline.copyWith(goal: WeightGoal.maintain));
      expect(maintain.proteinG, closeTo(1.6 * 62, 0.05));
    });

    test('极端体型下碳水不为负', () {
      const extreme = UserProfile(
        sex: Sex.female,
        age: 20,
        heightCm: 150,
        weightKg: 120,
        activity: ActivityLevel.sedentary,
        pace: LossPace.aggressive,
      );
      expect(_svc.calculate(extreme).carbG, greaterThanOrEqualTo(0));
    });
  });

  group('分餐与周期换算', () {
    test('分餐比例之和等于预算', () {
      final b = _svc.calculate(_baseline);
      final split = _svc.splitByMeal(b);
      final sum = split.values.fold<double>(0, (s, v) => s + v);
      expect(sum, closeTo(b.intakeTarget, 0.5));
      expect(split.keys, containsAll(['breakfast', 'lunch', 'dinner', 'snack']));
    });

    test('daysToTarget 与 weeksToGoal 方向一致', () {
      final p = _baseline.copyWith(pace: LossPace.gentle);
      final b = _svc.calculate(p);
      final days = _svc.daysToTarget(p, b);

      if (b.deficit > 0) {
        expect(days, greaterThan(0));
        // 周数向上取整，天数除以 7 向上取整应与之相等
        expect((days / 7).ceil(), p.weeksToGoal);
      }
    });
  });
}
