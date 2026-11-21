// lib/features/weight_loss/models/weight_loss_models.dart
//
// 减脂模块领域模型。无第三方依赖，可直接复制进月记项目。
// 设计原则：
//   1) 只读值对象（const），便于 Riverpod 做相等性比较与 rebuild 控制
//   2) 计算与数据分离：本文件不含任何公式
//   3) 所有枚举都带 label，UI 层直接取用，避免散落的 if/switch

import 'dart:math' as math;

/// 生理性别。BMR 公式对男女系数不同，必须显式区分。
enum Sex {
  male('男'),
  female('女');

  const Sex(this.label);
  final String label;
}

/// 日常活动水平（对应 TDEE 活动系数）。
/// 系数取自 FAO/WHO 与 Harris-Benedict 修订惯例，业界通用。
enum ActivityLevel {
  sedentary(1.200, '久坐少动', '几乎不运动，办公室为主'),
  light(1.375, '轻度活动', '每周 1–3 次轻运动'),
  moderate(1.550, '中度活动', '每周 3–5 次运动'),
  active(1.725, '高度活动', '每周 6–7 次运动'),
  veryActive(1.900, '极高活动', '体力工作或每天两次训练');

  const ActivityLevel(this.factor, this.label, this.hint);
  final double factor;
  final String label;
  final String hint;
}

/// 减脂目标。
enum WeightGoal {
  lose('减脂', -1),
  maintain('维持', 0),
  gain('增重', 1);

  const WeightGoal(this.label, this.sign);
  final String label;
  final int sign;
}

/// 减重速度档位。数值为「每周减重克数」，用于换算每日热量缺口。
/// 500 g/周 ≈ 550 kcal/日缺口（1 kg 脂肪 ≈ 7700 kcal）。
enum LossPace {
  gentle(250, '温和', '每周约 0.25 kg'),
  standard(500, '标准', '每周约 0.5 kg'),
  aggressive(750, '较快', '每周约 0.75 kg');

  const LossPace(this.gramPerWeek, this.label, this.hint);
  final int gramPerWeek;
  final String label;
  final String hint;

  /// 每日热量缺口（kcal）
  double get dailyDeficit => gramPerWeek / 1000.0 * 7700 / 7.0;
}

/// 用户档案。减脂计算的全部输入。
class UserProfile {
  const UserProfile({
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    this.goal = WeightGoal.lose,
    this.pace = LossPace.standard,
    this.targetWeightKg,
    this.bodyFatPercent,
  });

  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activity;
  final WeightGoal goal;
  final LossPace pace;

  /// 目标体重；为空时由 [targetBmi] 推导。
  final double? targetWeightKg;

  /// 体脂率（%），有值时改用 Katch-McArdle 公式算 BMR，更准。
  final double? bodyFatPercent;

  /// 默认目标 BMI 取 22（中国成人正常区间中位）。
  static const double targetBmi = 22.0;

  double get bmi => weightKg / math.pow(heightCm / 100.0, 2);

  /// 目标体重：优先用户显式设定，否则按 BMI 22 反推。
  double get resolvedTargetWeight =>
      targetWeightKg ?? targetBmi * math.pow(heightCm / 100.0, 2);

  /// 还需减去的体重（可为负，表示需增重）。
  double get remainingKg => weightKg - resolvedTargetWeight;

  /// 按当前速度，达成目标所需周数。
  /// 若体重已经越过目标（如想减脂但已低于目标体重），返回 0——此时应改用「维持」。
  int get weeksToGoal {
    if (goal == WeightGoal.maintain) return 0;
    if (goal == WeightGoal.lose && remainingKg <= 0.05) return 0;
    if (goal == WeightGoal.gain && remainingKg >= -0.05) return 0;
    final delta = remainingKg.abs();
    final perWeekKg = pace.gramPerWeek / 1000.0;
    if (perWeekKg <= 0) return 0;
    return (delta / perWeekKg).ceil();
  }

  /// 实际生效的目标：若「想减脂」但已低于目标体重，自动降级为维持，
  /// 避免给一个 BMI 已经偏低的人再算热量缺口。
  WeightGoal get effectiveGoal {
    if (goal == WeightGoal.lose && remainingKg <= 0.05) return WeightGoal.maintain;
    if (goal == WeightGoal.gain && remainingKg >= -0.05) return WeightGoal.maintain;
    return goal;
  }

  UserProfile copyWith({
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    ActivityLevel? activity,
    WeightGoal? goal,
    LossPace? pace,
    double? targetWeightKg,
    double? bodyFatPercent,
  }) {
    return UserProfile(
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      activity: activity ?? this.activity,
      goal: goal ?? this.goal,
      pace: pace ?? this.pace,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      bodyFatPercent: bodyFatPercent ?? this.bodyFatPercent,
    );
  }
}

/// 热量预算计算结果。UI 一次拿全，避免页面里重复算。
class CalorieBudget {
  const CalorieBudget({
    required this.bmr,
    required this.tdee,
    required this.intakeTarget,
    required this.deficit,
    required this.proteinG,
    required this.fatG,
    required this.carbG,
    required this.isFloored,
    required this.bmrFormula,
  });

  /// 基础代谢（kcal/日）
  final double bmr;

  /// 每日总消耗（kcal/日）= BMR × 活动系数
  final double tdee;

  /// 建议摄入（kcal/日）
  final double intakeTarget;

  /// 实际热量缺口（kcal/日）；维持目标时为 0
  final double deficit;

  /// 三大营养素目标（克）
  final double proteinG;
  final double fatG;
  final double carbG;

  /// 是否触发了安全下限（说明理论缺口过大，已被抬升）
  final bool isFloored;

  /// 实际使用的 BMR 公式名，便于在设置页展示"算法来源"
  final String bmrFormula;

  /// 预计每周体重变化（kg），负数为减。
  double get weeklyChangeKg => -deficit * 7 / 7700;
}

/// 单餐热量分配
class MealSplit {
  const MealSplit({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });

  final double breakfast;
  final double lunch;
  final double dinner;
  final double snack;

  /// 默认分配：早 25% / 午 35% / 晚 30% / 加餐 10%
  static const MealSplit standard = MealSplit(
    breakfast: 0.25,
    lunch: 0.35,
    dinner: 0.30,
    snack: 0.10,
  );
}

/// 食物条目（每 100 g 的营养值）。
class FoodItem {
  const FoodItem({
    required this.code,
    required this.name,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
    required this.carbPer100g,
    required this.category,
    this.unitGrams = 100,
    this.unitName = '份',
  });

  final String code;
  final String name;
  final double kcalPer100g;
  final double proteinPer100g;
  final double fatPer100g;
  final double carbPer100g;

  /// staple / protein / vegetable / fruit / dairy / fat
  final String category;

  /// 一份的克数（如 1 个鸡蛋 ≈ 50 g）
  final double unitGrams;
  final String unitName;

  double kcalOf(double grams) => kcalPer100g * grams / 100.0;
}

/// 餐单中的一项：食物 + 建议克数。
class MealEntry {
  const MealEntry({
    required this.food,
    required this.grams,
    required this.meal,
  });

  final FoodItem food;
  final double grams;

  /// breakfast / lunch / dinner / snack
  final String meal;

  double get kcal => food.kcalOf(grams);
  double get protein => food.proteinPer100g * grams / 100.0;
  double get fat => food.fatPer100g * grams / 100.0;
  double get carb => food.carbPer100g * grams / 100.0;
}

/// 一天的计划
class DayPlan {
  const DayPlan({
    required this.dayIndex,
    required this.date,
    required this.entries,
  });

  /// 第几天（0-based）
  final int dayIndex;
  final DateTime date;
  final List<MealEntry> entries;

  double get totalKcal => entries.fold(0.0, (s, e) => s + e.kcal);
  double get totalProtein => entries.fold(0.0, (s, e) => s + e.protein);
  double get totalFat => entries.fold(0.0, (s, e) => s + e.fat);
  double get totalCarb => entries.fold(0.0, (s, e) => s + e.carb);

  List<MealEntry> byMeal(String meal) =>
      entries.where((e) => e.meal == meal).toList(growable: false);
}

/// 多日计划（7 天 / 30 天）
class MultiDayPlan {
  const MultiDayPlan({required this.days, required this.budget});

  final List<DayPlan> days;
  final CalorieBudget budget;

  int get length => days.length;
}
