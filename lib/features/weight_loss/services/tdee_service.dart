// lib/features/weight_loss/services/tdee_service.dart
//
// 热量预算计算：BMR → TDEE → 建议摄入 → 三大营养素。
// 纯函数、无 IO、无状态，方便单元测试。
//
// 公式来源（均为公开发表的营养学标准）：
//   · Mifflin-St Jeor (1990)：当前临床与运动营养领域首选 BMR 估算式
//       男：10×W + 6.25×H − 5×A + 5
//       女：10×W + 6.25×H − 5×A − 161
//   · Katch-McArdle：已知体脂率时更准
//       BMR = 370 + 21.6 × 去脂体重(kg)
//   · TDEE = BMR × 活动系数
//   · 1 kg 脂肪 ≈ 7700 kcal

import 'dart:math' as math;

import '../models/weight_loss_models.dart';

class TdeeService {
  const TdeeService();

  /// 绝对安全下限（kcal/日）。低于此值长期执行有营养风险，业界的保守惯例。
  static const double _floorMale = 1500;
  static const double _floorFemale = 1200;

  /// 缺口上限占 TDEE 的比例。超过 25% 难以持续，且易掉肌肉。
  static const double _maxDeficitRatio = 0.25;

  /// 计算 BMR（kcal/日）
  double bmr(UserProfile p) {
    final fat = p.bodyFatPercent;
    if (fat != null && fat > 3 && fat < 65) {
      // Katch-McArdle：需要去脂体重
      final leanMass = p.weightKg * (1 - fat / 100.0);
      return 370 + 21.6 * leanMass;
    }
    // Mifflin-St Jeor
    final base = 10 * p.weightKg + 6.25 * p.heightCm - 5 * p.age;
    return p.sex == Sex.male ? base + 5 : base - 161;
  }

  /// BMR 公式名（给设置页展示来源用）
  String bmrFormulaName(UserProfile p) {
    final fat = p.bodyFatPercent;
    if (fat != null && fat > 3 && fat < 65) return 'Katch-McArdle';
    return 'Mifflin-St Jeor';
  }

  /// 完整预算
  CalorieBudget calculate(UserProfile p) {
    final bmrValue = bmr(p);
    final tdee = bmrValue * p.activity.factor;

    // 0) 目标校正：已越过目标体重时自动降级为「维持」
    final goal = p.effectiveGoal;

    // 1) 目标缺口
    double targetDeficit = 0;
    if (goal == WeightGoal.lose) {
      targetDeficit = p.pace.dailyDeficit;
    } else if (goal == WeightGoal.gain) {
      targetDeficit = -300; // 增重：每日盈余 300 kcal
    }

    // 2) 缺口封顶（不超过 TDEE 的 25%）
    final maxDeficit = tdee * _maxDeficitRatio;
    if (targetDeficit > maxDeficit) targetDeficit = maxDeficit;

    // 3) 得出摄入
    var intake = tdee - targetDeficit;

    // 4) 安全下限：不低于 BMR，也不低于性别绝对下限
    final absoluteFloor =
        p.sex == Sex.male ? _floorMale : _floorFemale;
    final minIntake = math.max(bmrValue, absoluteFloor);
    final floored = intake < minIntake;
    if (floored) intake = minIntake;

    // 5) 实际缺口（修正后）
    final actualDeficit = tdee - intake;

    // 6) 三大营养素
    //    蛋白质：减脂期 1.8 g/kg（保肌），维持/增重 1.6 g/kg
    final proteinPerKg = goal == WeightGoal.lose ? 1.8 : 1.6;
    var proteinG = proteinPerKg * p.weightKg;
    //    脂肪：占摄入 25%
    var fatG = intake * 0.25 / 9.0;
    //    碳水：剩余
    var carbG = (intake - proteinG * 4 - fatG * 9) / 4.0;

    // 极端体型兜底：碳水不为负
    if (carbG < 0) {
      // 先压蛋白质到 1.4 g/kg，再压脂肪到 20%
      proteinG = math.min(proteinG, 1.4 * p.weightKg);
      fatG = intake * 0.20 / 9.0;
      carbG = math.max(0, (intake - proteinG * 4 - fatG * 9) / 4.0);
    }

    return CalorieBudget(
      bmr: _round(bmrValue),
      tdee: _round(tdee),
      intakeTarget: _round(intake),
      deficit: _round(actualDeficit),
      proteinG: _round(proteinG),
      fatG: _round(fatG),
      carbG: _round(carbG),
      isFloored: floored,
      bmrFormula: bmrFormulaName(p),
    );
  }

  /// 按 MealSplit 把每日预算拆到四餐
  Map<String, double> splitByMeal(
    CalorieBudget budget, [
    MealSplit split = MealSplit.standard,
  ]) {
    final t = budget.intakeTarget;
    return {
      'breakfast': _round(t * split.breakfast),
      'lunch': _round(t * split.lunch),
      'dinner': _round(t * split.dinner),
      'snack': _round(t * split.snack),
    };
  }

  /// 估算达到目标体重所需天数（按当前缺口线性外推）。
  /// 返回 -1 表示目标与热量方向矛盾（例如目标要减重但实际是热量盈余）。
  int daysToTarget(UserProfile p, CalorieBudget b) {
    final goal = p.effectiveGoal;
    if (goal == WeightGoal.maintain) return 0;

    final deltaKg = p.remainingKg; // >0：还需减重；<0：还需增重
    if (deltaKg.abs() <= 0.05) return 0;

    // 方向校验：减脂要求 deltaKg>0，增重要求 deltaKg<0
    if (goal == WeightGoal.lose && deltaKg <= 0) return -1;
    if (goal == WeightGoal.gain && deltaKg >= 0) return -1;

    final mag = b.deficit.abs(); // 每日热量缺口/盈余的绝对值
    if (mag <= 0) return -1;

    // 每日体重变化量 = mag / 7700 (kg)
    return (deltaKg.abs() / (mag / 7700.0)).ceil();
  }

  double _round(double v) => (v * 10).roundToDouble() / 10;
}
