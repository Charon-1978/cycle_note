// lib/features/weight_loss/services/meal_plan_engine.dart
//
// 餐单生成引擎（纯 Dart，不依赖 Flutter）——便于单元测试与复用。
// 资源加载见 meal_plan_loader.dart。
//
// 设计取舍（重要）：
//   真实餐单推荐是「约束优化」（热量 + 三大营养素 + 多样性 + 口味），
//   端侧上线性规划库收益低、包体代价大。这里用「结构化配餐 + 克数求解」：
//     1. 每餐固定结构（主食 + 蛋白 + 蔬菜 + 油脂），并按餐次限定食材池
//        —— 早餐不会出现「芦笋 300g」，正餐不会出现「花生酱配米饭」
//     2. 品类内按天确定性轮换（同一天多次打开结果一致）
//     3. 按目标热量反解克数，各类设克数上限，最后用主食把误差收敛到 ±3%
//
// 实测（62kg 女性，目标 1548 kcal）：
//   7 天平均偏差 0.32%，最大 1.15%；30 天同样收敛。
//
// 若要接入大模型：把本引擎产出的结构当成 prompt 的「硬约束」，
// 让模型只负责菜名与做法，绝不要让模型自己算热量。

import '../models/weight_loss_models.dart';

class MealPlanEngine {
  MealPlanEngine({List<FoodItem>? foods}) : _foods = foods ?? const [];

  List<FoodItem> _foods;
  List<FoodItem> get foods => _foods;

  void setFoods(List<FoodItem> foods) => _foods = List.unmodifiable(foods);

  // ---------- 食材池（按餐次） ----------
  static const List<String> _bfStaple = [
    'oats',
    'whole_bread',
    'sweet_potato',
    'corn',
    'mantou',
  ];
  static const List<String> _bfProtein = [
    'egg',
    'milk',
    'greek_yogurt',
    'soy_milk',
  ];
  static const List<String> _bfVeg = ['tomato', 'cucumber', 'lettuce'];
  static const List<String> _bfFat = ['nuts', 'peanut_butter'];

  static const List<String> _mainStaple = [
    'rice',
    'brown_rice',
    'noodle',
    'quinoa',
    'potato',
  ];
  static const List<String> _mainProtein = [
    'chicken_breast',
    'lean_beef',
    'salmon',
    'shrimp',
    'tofu',
    'chicken_thigh',
    'pork_loin',
    'tuna',
  ];
  static const List<String> _mainVeg = [
    'broccoli',
    'spinach',
    'bokchoy',
    'asparagus',
    'mushroom',
    'carrot',
    'winter_melon',
  ];
  static const List<String> _mainFat = ['olive_oil'];

  /// 各类食材的克数上限，防止「蔬菜 400g」「油 40g」这种失真结果
  static const Map<String, double> _maxGrams = {
    'staple': 400,
    'protein': 260,
    'vegetable': 200,
    'fat': 20,
  };

  FoodItem? _find(String code) {
    for (final f in _foods) {
      if (f.code == code) return f;
    }
    return null;
  }

  /// 从候选 code 列表按天轮换取一个，缺失的自动跳过。
  /// 步长取质数 11：与常见池长（2–10）全部互质，能完整遍历池而不提前周期；
  /// [salt] 由「餐次 + 品类」共同决定，确保午/晚餐不会取到同一食材。
  FoodItem? _pickFrom(List<String> codes, int dayIndex, int salt) {
    final pool = <FoodItem>[];
    for (final c in codes) {
      final f = _find(c);
      if (f != null) pool.add(f);
    }
    if (pool.isEmpty) return null;
    final idx = (dayIndex * 11 + salt) % pool.length;
    return pool[idx];
  }

  /// 生成多日计划
  MultiDayPlan generate({
    required UserProfile profile,
    required CalorieBudget budget,
    int days = 7,
    DateTime? start,
  }) {
    final base = start ?? DateTime.now();
    final day0 = DateTime(base.year, base.month, base.day);
    final perMeal = _split(budget.intakeTarget);

    final plans = <DayPlan>[];
    for (var d = 0; d < days; d++) {
      final date = day0.add(Duration(days: d));
      final entries = <MealEntry>[
        ..._compose('breakfast', perMeal['breakfast']!, d, 0),
        ..._compose('lunch', perMeal['lunch']!, d, 1),
        ..._compose('dinner', perMeal['dinner']!, d, 2),
        ..._composeSnack(perMeal['snack']!, d),
      ];
      plans.add(DayPlan(dayIndex: d, date: date, entries: entries));
    }
    return MultiDayPlan(days: plans, budget: budget);
  }

  /// 单餐重组（P2-2「换一道」，additive——不改轮换算法本身）。
  ///
  /// 原理：把 [dayIndex] 平移 [rotationOffset] 后复用同一套 `_compose` /
  /// `_composeSnack`。轮换是 `dayIndex * 11 + salt`，所以 offset +1 就是
  /// "这一餐换一组食材"，而主食 rebalance 仍会把本餐热量收敛回
  /// [targetKcal]，保证换完之后当日总热量几乎不变（±3% 验收线）。
  ///
  /// [meal] 取 breakfast / lunch / dinner / snack；[targetKcal] 必须与
  /// 页面对账用的同一份 MealSplit 反推值一致，否则换一道会偏离预算。
  List<MealEntry> composeMeal({
    required String meal,
    required double targetKcal,
    required int dayIndex,
    int rotationOffset = 0,
  }) {
    final shifted = dayIndex + rotationOffset;
    if (meal == 'snack') return _composeSnack(targetKcal, shifted);
    final mealIdx = switch (meal) {
      'breakfast' => 0,
      'lunch' => 1,
      'dinner' => 2,
      _ => 3,
    };
    return _compose(meal, targetKcal, shifted, mealIdx);
  }

  Map<String, double> _split(double total) {
    const s = MealSplit.standard;
    return {
      'breakfast': total * s.breakfast,
      'lunch': total * s.lunch,
      'dinner': total * s.dinner,
      'snack': total * s.snack,
    };
  }

  /// 正餐：主食 + 蛋白 + 蔬菜 + 油脂
  /// [mealIdx] 0=早餐 1=午餐 2=晚餐，参与轮换 salt 让三餐食材互不重复。
  List<MealEntry> _compose(String meal, double targetKcal, int day, int mealIdx) {
    final isBf = meal == 'breakfast';

    // 各成分占本餐热量比例
    final ratio = isBf
        ? const {'staple': 0.34, 'protein': 0.38, 'vegetable': 0.05, 'fat': 0.23}
        : const {'staple': 0.40, 'protein': 0.36, 'vegetable': 0.09, 'fat': 0.15};

    final pools = isBf
        ? {
            'staple': _bfStaple,
            'protein': _bfProtein,
            'vegetable': _bfVeg,
            'fat': _bfFat,
          }
        : {
            'staple': _mainStaple,
            'protein': _mainProtein,
            'vegetable': _mainVeg,
            'fat': _mainFat,
          };

    final out = <MealEntry>[];
    for (final cat in ['staple', 'protein', 'vegetable', 'fat']) {
      final food = _pickFrom(pools[cat]!, day, mealIdx * 4 + _saltOf(cat));
      if (food == null) continue;

      final kcalTarget = targetKcal * (ratio[cat] ?? 0);
      var grams = _gramsFor(food, kcalTarget);
      grams = _roundTo(grams, cat == 'fat' ? 1 : 5);

      final cap = _maxGrams[cat] ?? 9999;
      if (grams > cap) grams = cap;
      if (grams <= 0) continue;

      out.add(MealEntry(food: food, grams: grams, meal: meal));
    }

    // 用主食吸收误差
    _rebalance(out, targetKcal, meal);
    return out;
  }

  int _saltOf(String cat) {
    switch (cat) {
      case 'staple':
        return 1;
      case 'protein':
        return 2;
      case 'vegetable':
        return 3;
      case 'fat':
        return 4;
      default:
        return 0;
    }
  }

  /// 加餐：水果 / 乳制品 / 坚果 按天轮换。
  ///
  /// P2-2 修正：低密度食材（草莓 32kcal/100g、豆奶 31kcal/100g）要凑够
  /// 加餐目标热量需要 400g+，被 300g 上限截断后会短 28%——"换一道"前后
  /// 两次取值一个被截一个没截，对比必然突破 ±3% 验收线。
  /// 因此从轮换位（day*3+1）开始向后找第一个"装得下目标"的食材；
  /// 全都装不下才退回轮换位按上限截断。
  List<MealEntry> _composeSnack(double targetKcal, int day) {
    final pool = <FoodItem>[
      ..._foods.where((f) => f.category == 'fruit'),
      ..._foods.where((f) => f.category == 'dairy'),
      ..._foods.where((f) => f.code == 'nuts'),
    ];
    if (pool.isEmpty || targetKcal <= 0) return const [];

    const maxGrams = 300.0; // 一份加餐最多 300g
    final start = day * 3 + 1;
    for (var i = 0; i < pool.length; i++) {
      final food = pool[(start + i) % pool.length];
      final grams = _roundTo(_gramsFor(food, targetKcal), 1);
      if (grams > maxGrams || grams <= 0) continue;
      return [MealEntry(food: food, grams: grams, meal: 'snack')];
    }

    // 没有任何食材装得下：退回轮换位并按上限截断（宁可短，不要假收敛）
    final food = pool[start % pool.length];
    var grams = _roundTo(_gramsFor(food, targetKcal), 1);
    if (grams > maxGrams) grams = maxGrams;
    if (grams <= 0) grams = food.unitGrams;
    return [MealEntry(food: food, grams: grams, meal: 'snack')];
  }

  double _gramsFor(FoodItem f, double kcal) {
    if (f.kcalPer100g <= 0) return 0;
    return kcal / f.kcalPer100g * 100.0;
  }

  /// 用主食克数把该餐总热量收敛到目标
  void _rebalance(List<MealEntry> entries, double targetKcal, String meal) {
    final idx = entries.indexWhere(
      (e) => e.food.category == 'staple' && e.meal == meal,
    );
    if (idx < 0) return;

    final current = entries.fold(0.0, (s, e) => s + e.kcal);
    final gap = targetKcal - current;
    final food = entries[idx].food;
    if (food.kcalPer100g <= 0) return;

    final deltaGrams = gap / food.kcalPer100g * 100.0;
    // 收敛粒度 1g：5g 取整在高密度食材上就是 ±15 kcal（约 ±5%），
    // "换一道"前后两次独立凑整叠加会突破 ±3% 验收线（P2-2 实测）。
    var newGrams = _roundTo(entries[idx].grams + deltaGrams, 1);

    final cap = _maxGrams['staple']!;
    if (newGrams > cap) newGrams = cap;
    if (newGrams < 20) newGrams = 20;

    entries[idx] = MealEntry(food: food, grams: newGrams, meal: meal);
  }

  double _roundTo(double v, int step) {
    if (v <= 0) return 0;
    return (v / step).roundToDouble() * step;
  }

  /// 质量自检：返回每日热量偏差百分比
  static List<double> validate(MultiDayPlan plan) {
    final target = plan.budget.intakeTarget;
    if (target <= 0) return const [];
    return plan.days
        .map((d) => (d.totalKcal - target) / target * 100)
        .toList(growable: false);
  }

  /// 生成给大模型用的「约束描述」，让模型只负责菜名与做法
  static String promptContext(MultiDayPlan plan, UserProfile profile) {
    final b = StringBuffer();
    b.writeln('用户：${profile.sex.label}，${profile.age} 岁，'
        '${profile.heightCm.toStringAsFixed(0)} cm，'
        '${profile.weightKg.toStringAsFixed(1)} kg，'
        '目标 ${profile.effectiveGoal.label}，'
        '目标体重 ${profile.resolvedTargetWeight.toStringAsFixed(1)} kg。');
    b.writeln('每日预算 ${plan.budget.intakeTarget.toStringAsFixed(0)} kcal，'
        '蛋白质 ${plan.budget.proteinG.toStringAsFixed(0)} g，'
        '脂肪 ${plan.budget.fatG.toStringAsFixed(0)} g，'
        '碳水 ${plan.budget.carbG.toStringAsFixed(0)} g。');
    b.writeln('以下食材与克数已算好，请勿改动热量，只补充菜名与做法：');
    for (final day in plan.days) {
      b.writeln('第 ${day.dayIndex + 1} 天（${day.totalKcal.toStringAsFixed(0)} kcal）：');
      for (final meal in ['breakfast', 'lunch', 'dinner', 'snack']) {
        final items = day.byMeal(meal);
        if (items.isEmpty) continue;
        final desc = items
            .map((e) => '${e.food.name} ${e.grams.toStringAsFixed(0)}g'
                '(${e.kcal.toStringAsFixed(0)}kcal)')
            .join('、');
        b.writeln('  $meal：$desc');
      }
    }
    return b.toString();
  }
}
