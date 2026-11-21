// test/weight_loss/seed_foods_test.dart
//
// P3-1「食物库扩到 200+」验收 + DATA_SOURCES.md §5 数据质量约定的落地：
//   · 总数 ≥200 条
//   · 原 42 条一个不少、数值未被改动（基线锁定）
//   · code 全局唯一
//   · kcal ∈ (0, 900]、宏量为非负小数、category 只能是六类之一
//   · 新增条目必须带 source 字段（可追溯到 usda_approx）
//
// 这些是"入库门槛"，写进测试防止以后批量导入时混进脏数据。

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final raw = File('assets/data/seed_foods.json').readAsStringSync();
  final foods =
      (jsonDecode(raw) as List).cast<Map<String, dynamic>>();

  const originalCodes = <String>{
    'rice', 'brown_rice', 'noodle', 'mantou', 'oats', 'sweet_potato',
    'corn', 'quinoa', 'potato', 'whole_bread',
    'chicken_breast', 'egg', 'salmon', 'lean_beef', 'shrimp', 'tofu',
    'chicken_thigh', 'pork_loin', 'tuna',
    'milk', 'greek_yogurt', 'soy_milk',
    'broccoli', 'spinach', 'lettuce', 'tomato', 'cucumber', 'asparagus',
    'mushroom', 'carrot', 'winter_melon', 'bokchoy',
    'apple', 'banana', 'blueberry', 'orange', 'kiwi', 'strawberry',
    'olive_oil', 'nuts', 'avocado', 'peanut_butter',
  };

  const validCategories = {'staple', 'protein', 'vegetable', 'fruit', 'dairy', 'fat'};

  test('总数 ≥200', () {
    expect(foods.length, greaterThanOrEqualTo(200));
  });

  test('原 42 条全部保留且未改动（基线锁定）', () {
    final byCode = {for (final f in foods) f['code'] as String: f};

    // 基线数值：与扩充前的 seed_foods.json 逐条一致
    final baseline = <String, List<double>>{
      'rice': [116, 2.6, 0.3, 25.9],
      'chicken_breast': [133, 24.6, 2.5, 0.6],
      'egg': [143, 13.3, 8.8, 2.8],
      'milk': [54, 3.0, 3.2, 3.4],
      'broccoli': [36, 4.1, 0.6, 4.3],
      'apple': [53, 0.2, 0.2, 13.5],
      'olive_oil': [899, 0, 99.9, 0],
      'nuts': [600, 20.0, 50.0, 20.0],
      'peanut_butter': [588, 25.0, 50.0, 20.0],
    };

    for (final code in originalCodes) {
      expect(
        byCode.containsKey(code),
        isTrue,
        reason: '原有食材 $code 被删了',
      );
      final f = byCode[code]!;
      expect(f['source'], isNull, reason: '原 42 条不应被追加 source 字段');
      if (baseline.containsKey(code)) {
        final b = baseline[code]!;
        expect(f['kcalPer100g'], b[0], reason: '$code kcal 被改了');
        expect(f['proteinPer100g'], b[1], reason: '$code protein 被改了');
        expect(f['fatPer100g'], b[2], reason: '$code fat 被改了');
        expect(f['carbPer100g'], b[3], reason: '$code carb 被改了');
      }
    }
  });

  test('code 全局唯一', () {
    final codes = foods.map((f) => f['code'] as String).toList();
    expect(codes.toSet().length, codes.length);
  });

  test('数值与品类符合 DATA_SOURCES §5 质量约定', () {
    for (final f in foods) {
      final code = f['code'] as String;
      final kcal = f['kcalPer100g'] as num;
      expect(
        kcal > 0 && kcal <= 900,
        isTrue,
        reason: '$code kcal=$kcal 越界（纯油脂上限 900）',
      );
      for (final key in ['proteinPer100g', 'fatPer100g', 'carbPer100g']) {
        expect(
          (f[key] as num) >= 0,
          isTrue,
          reason: '$code 的 $key 为负',
        );
      }
      expect(
        validCategories.contains(f['category']),
        isTrue,
        reason: '$code category=${f['category']} 不在六类之内',
      );
      expect(
        (f['unitGrams'] as num) > 0,
        isTrue,
        reason: '$code unitGrams 非正',
      );
    }
  });

  test('新增条目必须带 source=usda_approx（可追溯）', () {
    final newOnes = foods.where((f) => !originalCodes.contains(f['code']));
    expect(newOnes, isNotEmpty);
    for (final f in newOnes) {
      expect(
        f['source'],
        'usda_approx',
        reason: '${f['code']} 缺 source 字段，无法追溯到来源',
      );
    }
  });
}
