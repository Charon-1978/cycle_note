// test/weight_loss/dish_namer_test.dart
//
// P3-4「菜名润色（离线规则版）」验收：
//   · 确定性：同一组食材反复生成结果一致
//   · 典型组合：鸡胸+西兰花 →「香煎鸡胸配蒜蓉西兰花」式命名
//   · 覆盖率：203 条种子食材单独成餐都能得到非空菜名（不崩、不空串）
//   · 自建食物兜底：custom_* 用食材名本身，不猜烹饪方式
//   · 空餐次返回空串
//   · 30 天全量：每天四餐菜名全部非空
//
// 只锁文字规则，不锁"好不好听"——后者属于产品判断，锁了会阻碍调表。

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';
import 'package:cycle_note/features/weight_loss/services/dish_namer.dart';
import 'package:cycle_note/features/weight_loss/services/meal_plan_engine.dart';
import 'package:cycle_note/features/weight_loss/services/meal_plan_loader.dart';
import 'package:cycle_note/features/weight_loss/services/tdee_service.dart';

FoodItem food(String code, String name, String category) => FoodItem(
      code: code,
      name: name,
      kcalPer100g: 100,
      proteinPer100g: 10,
      fatPer100g: 5,
      carbPer100g: 10,
      category: category,
      unitGrams: 100,
      unitName: '份',
    );

MealEntry entry(FoodItem f, double grams) =>
    MealEntry(food: f, grams: grams, meal: 'dinner');

void main() {
  // setUpAll 里要读 assets（rootBundle），必须先初始化 binding
  TestWidgetsFlutterBinding.ensureInitialized();

  const namer = RuleBasedDishNamer();

  group('规则', () {
    test('鸡胸 + 西兰花 + 米饭 → 香煎鸡胸配蒜蓉西兰花（另配米饭）', () {
      final entries = [
        entry(food('rice', '米饭', 'staple'), 150),
        entry(food('chicken_breast', '鸡胸肉', 'protein'), 120),
        entry(food('broccoli', '西兰花', 'vegetable'), 100),
        entry(food('olive_oil', '橄榄油', 'fat'), 5),
      ];
      expect(namer.name(entries, 'dinner'), '香煎鸡胸配蒜蓉西兰花（另配米饭）');
    });

    test('无主食 → 纯「主菜配配菜」', () {
      final entries = [
        entry(food('chicken_breast', '鸡胸肉', 'protein'), 120),
        entry(food('broccoli', '西兰花', 'vegetable'), 100),
        entry(food('olive_oil', '橄榄油', 'fat'), 5),
      ];
      expect(namer.name(entries, 'dinner'), '香煎鸡胸配蒜蓉西兰花');
    });

    test('有主食时追加「另配」', () {
      final entries = [
        entry(food('brown_rice', '糙米饭', 'staple'), 150),
        entry(food('salmon', '三文鱼', 'protein'), 120),
        entry(food('spinach', '菠菜', 'vegetable'), 100),
      ];
      final n = namer.name(entries, 'lunch');
      expect(n, startsWith('盐烤三文鱼配蒜蓉菠菜'));
      expect(n, contains('另配糙米饭'));
    });

    test('无蛋白 → 主食当主菜', () {
      final entries = [
        entry(food('rice', '米饭', 'staple'), 150),
        entry(food('cucumber', '黄瓜', 'vegetable'), 100),
      ];
      final n = namer.name(entries, 'dinner');
      expect(n, contains('米饭'));
      expect(n, contains('拍黄瓜'));
    });

    test('早餐按固定类别顺序展开', () {
      final entries = [
        entry(food('egg', '鸡蛋', 'protein'), 50),
        entry(food('oats', '燕麦片', 'staple'), 40),
        entry(food('milk', '牛奶', 'dairy'), 250),
        entry(food('tomato', '番茄', 'vegetable'), 80),
      ];
      expect(
        namer.name(entries, 'breakfast'),
        '燕麦片 + 水煮蛋 + 牛奶 + 凉拌番茄',
      );
    });

    test('加餐直接报食材名；空餐次返回空串', () {
      expect(
        namer.name([entry(food('nuts', '混合坚果', 'fat'), 20)], 'snack'),
        '混合坚果',
      );
      expect(namer.name(const [], 'dinner'), '');
    });

    test('自建食物兜底：蛋白类加"轻煎"，其他类用本名', () {
      final customProtein = food('custom_a', '妈妈牌狮子头', 'protein');
      final customOther = food('custom_b', '外婆牌糯米糕', 'staple');
      expect(
        namer.name([entry(customProtein, 100)], 'dinner'),
        '轻煎妈妈牌狮子头',
      );
      expect(namer.name([entry(customOther, 100)], 'dinner'), '外婆牌糯米糕');
    });

    test('确定性：同一组食材 100 次生成结果一致', () {
      final entries = [
        entry(food('quinoa', '藜麦(熟)', 'staple'), 150),
        entry(food('shrimp', '虾仁', 'protein'), 100),
        entry(food('asparagus', '芦笋', 'vegetable'), 100),
      ];
      final first = namer.name(entries, 'dinner');
      for (var i = 0; i < 100; i++) {
        expect(namer.name(entries, 'dinner'), first);
      }
    });
  });

  group('全量覆盖', () {
    late MealPlanEngine engine;
    late UserProfile profile;
    late CalorieBudget budget;

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
    });

    test('203 条种子食材单独成餐都能得到非空菜名', () async {
      final foods = await MealPlanLoader.instance.loadSeedFoods();
      expect(foods.length, greaterThanOrEqualTo(200));
      for (final f in foods) {
        final n = namer.name([entry(f, 100)], 'dinner');
        expect(n, isNotEmpty, reason: '食材 ${f.code} 生成了空菜名');
      }
    });

    test('30 天 × 四餐全部有菜名（真实引擎组合）', () {
      final plan = engine.generate(profile: profile, budget: budget, days: 30);
      for (final day in plan.days) {
        for (final meal in const ['breakfast', 'lunch', 'dinner', 'snack']) {
          final entries = day.byMeal(meal);
          if (entries.isEmpty) continue;
          final n = namer.name(entries, meal);
          expect(
            n,
            isNotEmpty,
            reason: '第 ${day.dayIndex + 1} 天 $meal 生成了空菜名',
          );
        }
      }
    });
  });
}
