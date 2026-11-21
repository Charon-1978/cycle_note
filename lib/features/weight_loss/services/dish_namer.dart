// lib/features/weight_loss/services/dish_namer.dart
//
// 菜名润色（P3-4，离线规则版，用户已确认不接云服务）。
//
// 设计决策（对应可行性计划书 P3-4）：
//   · **确定性**：同一组食材永远得到同一个菜名——不随时间、随机数变化。
//     这是产品语义："照着菜名买菜" 不能今天明天不一样。
//   · **规则可解释**：名称 = 烹饪动词表 + 食材名，全部来自本地映射表，
//     用户问"为什么叫这个"可以回答。
//   · **热量纪律不变**：这里只生成文字，绝不碰克数与热量
//     （引擎注释里写的口径：模型只负责菜名，绝不负责计算）。
//
// 预留接口 [AiDishNamer]：以后接 LLM 时实现它，把引擎产出的
// MealEntry 结构当硬约束喂给模型，让模型只补菜名与做法。
// 在接通之前，UI 永远使用 [RuleBasedDishNamer]，不会出现"假 AI"。

import '../models/weight_loss_models.dart';

/// 菜名生成接口。
abstract class DishNamer {
  /// 生成一餐的菜名。[entries] 为空时返回空串（UI 不显示）。
  String name(List<MealEntry> entries, String mealType);
}

/// 预留：接大模型时的接口（当前无实现，未接线）。
///
/// 实现约定（将来写实现的人必读）：
///   1. 输入必须是引擎算好的 MealEntry（含克数/热量），模型**不得**修改；
///   2. 失败/超时必须回退到 [RuleBasedDishNamer]，不允许显示"生成中…"卡死；
///   3. 需要用户自己配 Key（BYOK），Key 不落日志、不进导出文件。
abstract class AiDishNamer extends DishNamer {}

class RuleBasedDishNamer implements DishNamer {
  const RuleBasedDishNamer();

  /// 蛋白类食材的烹饪命名（code → 菜名片段）。
  /// 没收录的食材走 _defaultMain 的兜底动词。
  static const Map<String, String> _proteinDishes = {
    'chicken_breast': '香煎鸡胸',
    'lean_beef': '黑椒牛肉',
    'salmon': '盐烤三文鱼',
    'shrimp': '白灼虾仁',
    'tofu': '家常豆腐',
    'chicken_thigh': '照烧鸡腿',
    'pork_loin': '嫩煎猪排',
    'tuna': '水浸金枪鱼',
    'egg': '水煮蛋',
    'milk': '温牛奶',
    'greek_yogurt': '希腊酸奶',
    'soy_milk': '无糖豆浆',
    'duck_breast': '香煎鸭胸',
    'turkey_breast': '嫩煎火鸡胸',
    'cod': '清蒸鳕鱼',
    'basa': '香煎巴沙鱼',
    'sole_fish': '清蒸龙利鱼',
    'sea_bass': '清蒸鲈鱼',
    'yellow_croaker': '清蒸黄花鱼',
    'hairtail': '香煎带鱼',
    'crucian_carp': '清蒸鲫鱼',
    'saury': '盐烤秋刀鱼',
    'eel': '蒲烧鳗鱼',
    'clam': '白灼蛤蜊',
    'scallop': '香煎扇贝',
    'oyster': '蒜蓉烤生蚝',
    'mussels': '白酒煮青口',
    'crab': '清蒸河蟹',
    'squid': '白灼鱿鱼',
    'cuttlefish': '白灼墨鱼',
    'quail_egg': '卤鹌鹑蛋',
    'preserved_egg': '凉拌皮蛋',
    'silken_tofu': '小葱拌豆腐',
    'dried_tofu': '卤豆干',
    'tofu_sheet': '凉拌千张',
    'fuzhu': '凉拌腐竹',
    'edamame': '盐水毛豆',
    'tempeh': '香煎天贝',
    'pork_liver': '卤猪肝',
    'chicken_liver': '卤鸡肝',
    'chicken_heart': '爆炒鸡心',
    'chicken_gizzard': '卤鸡胗',
    'beef_tripe': '凉拌牛肚',
  };

  /// 蔬菜类食材的配菜命名。
  static const Map<String, String> _vegDishes = {
    'broccoli': '蒜蓉西兰花',
    'spinach': '蒜蓉菠菜',
    'lettuce': '白灼生菜',
    'tomato': '凉拌番茄',
    'cucumber': '拍黄瓜',
    'asparagus': '白灼芦笋',
    'mushroom': '清炒蘑菇',
    'carrot': '清炒胡萝卜丝',
    'winter_melon': '清炒冬瓜',
    'bokchoy': '白灼小白菜',
    'napa_cabbage': '醋熘白菜',
    'baby_cabbage': '上汤娃娃菜',
    'indian_lettuce': '蒜香油麦菜',
    'celery': '清炒芹菜',
    'water_spinach': '蒜蓉空心菜',
    'chive': '清炒韭菜',
    'crown_daisy': '清炒茼蒿',
    'amaranth': '蒜蓉苋菜',
    'chinese_kale': '白灼芥蓝',
    'cauliflower': '干煸花菜',
    'eggplant': '清蒸茄子',
    'green_pepper': '虎皮青椒',
    'bell_pepper': '彩椒沙拉',
    'zucchini': '清炒西葫芦',
    'white_radish': '萝卜丝沙拉',
    'garlic_sprout': '清炒蒜苔',
    'onion': '洋葱圈',
    'okra': '白灼秋葵',
    'loofah': '清炒丝瓜',
    'bitter_melon': '凉拌苦瓜',
    'bean_sprout': '清炒黄豆芽',
    'mung_sprout': '清炒绿豆芽',
    'pea_shoot': '清炒豌豆苗',
    'shiitake': '烤香菇',
    'enoki': '凉拌金针菇',
    'king_oyster': '煎杏鲍菇',
    'oyster_mushroom': '清炒平菇',
    'wood_ear': '凉拌木耳',
    'bamboo_shoot': '油焖笋',
    'lettuce_stem': '清炒莴笋',
    'kelp_fresh': '凉拌海带丝',
    'snow_peas': '清炒荷兰豆',
    'green_bean': '干煸四季豆',
    'long_bean': '清炒豆角',
    'watercress': '西洋菜沙拉',
    'pumpkin': '蒸南瓜',
  };

  @override
  String name(List<MealEntry> entries, String mealType) {
    if (entries.isEmpty) return '';

    switch (mealType) {
      case 'snack':
        return entries.first.food.name;
      case 'breakfast':
        return _breakfastName(entries);
      default:
        return _mainMealName(entries);
    }
  }

  /// 早餐：按「主食→蛋白→乳制品→蔬菜→油脂」固定顺序展开，
  /// ' + ' 连接。不硬凑"西式/中式"，食材决定菜名。
  String _breakfastName(List<MealEntry> entries) {
    final ordered = _sortByCategory(
        entries, const ['staple', 'protein', 'dairy', 'vegetable', 'fat']);
    return ordered.map((e) => _cookedName(e.food)).join(' + ');
  }

  /// 正餐：主菜（蛋白优先）+「配」+ 蔬菜 + （另配主食）。
  /// 例子：香煎鸡胸配蒜蓉西兰花（另配糙米饭）
  String _mainMealName(List<MealEntry> entries) {
    final fats = entries.where((e) => e.food.category == 'fat').toList();
    final rest = entries.where((e) => e.food.category != 'fat').toList();
    if (rest.isEmpty) {
      // 全是油脂的极端情况（几乎不可能）→ 直接报食材名
      return fats.map((e) => _cookedName(e.food)).join(' · ');
    }

    MealEntry main;
    final proteins = rest.where((e) => e.food.category == 'protein').toList();
    final staples = rest.where((e) => e.food.category == 'staple').toList();
    if (proteins.isNotEmpty) {
      main = proteins.first;
    } else if (staples.isNotEmpty) {
      main = staples.first;
    } else {
      main = rest.first;
    }

    final vegs = rest
        .where((e) => e.food.category == 'vegetable' && !identical(e, main))
        .toList();
    final sides = <String>[];
    if (vegs.isNotEmpty) sides.add(_vegDish(vegs.first.food));
    final staplesLeft = rest
        .where((e) => e.food.category == 'staple' && !identical(e, main))
        .toList();
    if (staplesLeft.isNotEmpty) {
      return '${_mainDish(main.food)}配${sides.join('、')}'
          '（另配${staplesLeft.first.food.name}）';
    }
    if (sides.isEmpty) return _mainDish(main.food);
    return '${_mainDish(main.food)}配${sides.join('、')}';
  }

  /// 烹饪后的名称：映射表命中用表内名，否则用兜底动词 + 食材名。
  String _cookedName(FoodItem f) {
    switch (f.category) {
      case 'protein':
        return _mainDish(f);
      case 'vegetable':
        return _vegDish(f);
      case 'fat':
        // 油脂/坚果不参与"烹饪"，直接报名（橄榄油 5g 出现在名字里反而累赘）
        return f.name;
      default:
        return f.name;
    }
  }

  String _mainDish(FoodItem f) {
    final mapped = _proteinDishes[f.code];
    if (mapped != null) return mapped;
    // 兜底：给蛋白类一个通用动词，其他类直接报名。
    // 自建食物（custom_*）一定落到这里——不猜烹饪方式，食材名就是菜名。
    return f.category == 'protein' ? '轻煎${f.name}' : f.name;
  }

  String _vegDish(FoodItem f) => _vegDishes[f.code] ?? '清炒${f.name}';

  List<MealEntry> _sortByCategory(List<MealEntry> entries, List<String> order) {
    int rank(MealEntry e) {
      final i = order.indexOf(e.food.category);
      return i < 0 ? order.length : i;
    }

    final sorted = [...entries]..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        if (r != 0) return r;
        return a.food.code.compareTo(b.food.code);
      });
    return sorted;
  }
}
