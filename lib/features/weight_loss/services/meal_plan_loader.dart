// lib/features/weight_loss/services/meal_plan_loader.dart
//
// 把 assets 里的食物库/运动库读进内存，交给纯 Dart 引擎。
// 单独拆一个文件是为了让 meal_plan_engine.dart 保持无 Flutter 依赖、可单测。

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/weight_loss_models.dart';
import 'exercise_service.dart';
import 'meal_plan_engine.dart';

class MealPlanLoader {
  MealPlanLoader._();
  static final MealPlanLoader instance = MealPlanLoader._();

  final MealPlanEngine engine = MealPlanEngine();
  bool _loaded = false;

  /// 只读种子食物库，不动引擎。
  ///
  /// 饮食记录（P2-3）和餐单（P2-1）用的是同一份库，但两者的加载时机不同：
  /// 记录页需要"选食物"，餐单需要引擎算配比。共用解析逻辑、各自缓存，
  /// 避免一边加载状态影响另一边。
  Future<List<FoodItem>> loadSeedFoods() async {
    final raw = await rootBundle.loadString('assets/data/seed_foods.json');
    return (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(foodFromJson)
        .toList(growable: false);
  }

  /// 预加载食物库（建议在 app 启动或进入减脂 tab 时调用一次）
  Future<void> preload() async {
    if (_loaded) return;
    engine.setFoods(await loadSeedFoods());
    _loaded = true;
  }

  /// 若你以后从服务端拉食物库，用这个覆盖（并写入本地缓存）
  Future<void> preloadFrom(List<Map<String, dynamic>> json) async {
    engine.setFoods(json.map(foodFromJson).toList(growable: false));
    _loaded = true;
  }

  static FoodItem foodFromJson(Map<String, dynamic> m) => FoodItem(
        code: m['code'] as String,
        name: m['name'] as String,
        kcalPer100g: (m['kcalPer100g'] as num).toDouble(),
        proteinPer100g: (m['proteinPer100g'] as num).toDouble(),
        fatPer100g: (m['fatPer100g'] as num).toDouble(),
        carbPer100g: (m['carbPer100g'] as num).toDouble(),
        category: m['category'] as String,
        unitGrams: (m['unitGrams'] as num).toDouble(),
        unitName: m['unitName'] as String? ?? '份',
      );

  /// 一次性准备减脂模块需要的所有静态数据
  Future<void> warmUp() async {
    await Future.wait([preload(), ExerciseService.instance.load()]);
  }
}
