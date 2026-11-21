// lib/features/weight_loss/providers/weight_loss_providers.dart
//
// 减脂模块 Provider 链：
//   repository → 档案行 → 最新体重 → 领域 UserProfile → CalorieBudget
//
// 设计原则（和经期模块保持一致）：
//   1) 预算不落库也能算 —— 它是纯函数结果，Provider 每次从档案推导，
//      避免"改了档案但预算没刷新"的脏状态。
//   2) 落库的只有「每日预算快照」(CalorieBudgets)，因为回看历史时需要知道
//      那天给的是多少 —— 用户体重变了，预算会变，历史不能被重算掉。
//   3) 所有 Provider 都允许「档案为空」这一状态（value = null），
//      UI 用空态引导去填档案，而不是崩溃或显示 0。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database/app_database.dart';
import '../../../data/local/database/database_provider.dart';
import '../../weight_loss/services/exercise_service.dart' show ExerciseDef, ExerciseService;
import '../../weight_loss/services/meal_plan_loader.dart';
import '../data/profile_mapper.dart';
import '../data/weight_loss_repository.dart';
import '../models/weight_loss_models.dart';
import '../services/tdee_service.dart';

const TdeeService _tdee = TdeeService();

final weightLossRepositoryProvider = Provider<WeightLossRepository>((ref) {
  return WeightLossRepository(ref.watch(appDatabaseProvider));
});

/// 数据库里的档案行（原始）。从未填过 = null。
final bodyProfileRowProvider = FutureProvider<BodyProfile?>((ref) {
  return ref.watch(weightLossRepositoryProvider).profile();
});

/// 最新一次称重的体重（kg）。没有记录 = null。
final latestWeightProvider = FutureProvider<double?>((ref) {
  return ref.watch(weightLossRepositoryProvider).latestWeight();
});

/// 体重趋势（含 7 日移动平均）。
final weightTrendProvider = FutureProvider<List<WeightPoint>>((ref) {
  return ref.watch(weightLossRepositoryProvider).weightTrend();
});

/// 最近 30 天每日摄入/消耗序列（只含有记录的日子），供趋势页 P2-4。
final dailyEnergySeriesProvider = FutureProvider<List<EnergyPoint>>((ref) {
  return ref.watch(weightLossRepositoryProvider).dailyEnergySeries();
});

/// 领域模型。档案没填 = null。
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final row = await ref.watch(bodyProfileRowProvider.future);
  if (row == null) return null;
  final latest = await ref.watch(latestWeightProvider.future);
  return row.toDomain(currentWeightKg: latest);
});

/// 热量预算。档案没填 = null。
///
/// 注意：这里用 FutureProvider 而不是同步 Provider，是因为预算依赖异步的档案；
/// UI 侧统一 `.valueOrNull` 取用，加载中按 null 处理（显示骨架/空态）。
final calorieBudgetProvider = FutureProvider<CalorieBudget?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;
  return _tdee.calculate(profile);
});

/// 今天零点。作为 [dailyEnergyProvider] 的 family key。
///
/// 用日期而不 `DateTime.now()`：同一个 key 才能命中缓存，
/// 否则每次 rebuild 都会生成新 key、把旧结果丢掉重算。
final todayDateProvider = Provider<DateTime>((ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
});

/// 任意一天的热量汇总。档案没填 = null。
final dailyEnergyProvider =
    FutureProvider.family<DailyEnergySummary?, DateTime>((ref, day) async {
  final budget = await ref.watch(calorieBudgetProvider.future);
  if (budget == null) return null;
  return ref.watch(weightLossRepositoryProvider).summaryOf(day, budget);
});

/// 今日热量概况（摄入 / 运动消耗 / 剩余）。
final todayEnergyProvider = Provider<AsyncValue<DailyEnergySummary?>>((ref) {
  return ref.watch(dailyEnergyProvider(ref.watch(todayDateProvider)));
});

/// MET 运动表（本地 assets，首次读会加载并缓存）。
///
/// 放 FutureProvider 而不是同步 getter：assets 读取是异步的，
/// 同步暴露会让首帧拿到空列表，"50 项运动"变成"没有运动可选"。
final exerciseDefsProvider = FutureProvider<List<ExerciseDef>>((ref) async {
  await ExerciseService.instance.load();
  return ExerciseService.instance.all;
});

/// 最近 90 天运动记录（倒序）。
final exerciseLogsProvider = FutureProvider<List<ExerciseLog>>((ref) {
  return ref.watch(weightLossRepositoryProvider).exerciseLogs();
});

/// 食物库 = 种子库（assets）+ 用户自建（数据库）。
///
/// 自建食物排后面，但搜索时两种一起搜 —— 用户不关心食物是谁建的，
/// 只关心能不能搜到。
final foodLibraryProvider = FutureProvider<List<FoodItem>>((ref) async {
  final seed = await MealPlanLoader.instance.loadSeedFoods();
  final custom = await ref.watch(weightLossRepositoryProvider).customFoods();
  return [
    ...seed,
    ...custom.map((c) => FoodItem(
          code: c.code,
          name: c.name,
          kcalPer100g: c.kcalPer100g,
          proteinPer100g: c.proteinPer100g,
          fatPer100g: c.fatPer100g,
          carbPer100g: c.carbPer100g,
          category: c.category,
          unitGrams: c.unitGrams,
          unitName: c.unitName,
        )),
  ];
});

/// 今日饮食记录（倒序）。
final todayMealLogsProvider = FutureProvider<List<MealLog>>((ref) {
  return ref.watch(weightLossRepositoryProvider).mealLogs(
        day: ref.watch(todayDateProvider),
      );
});

/// 餐单（family：参数是天数 7/30，P2-2）。
///
/// 生成是确定性的（引擎按天轮换），所以同一天内重复打开结果一致；
/// 但预算或档案变了就必须重算，因此依赖 calorieBudgetProvider。
/// 档案没填 = null（页面用空态引导，不显示假餐单）。
///
/// 用 family 而不是页面里二次裁剪：7 天和 30 天是两次独立生成请求，
/// 各自缓存；切换 7/30 时另一份还在缓存里，来回切不重算。
final mealPlanProvider =
    FutureProvider.family<MultiDayPlan?, int>((ref, days) async {
  final budget = await ref.watch(calorieBudgetProvider.future);
  final profile = await ref.watch(userProfileProvider.future);
  if (budget == null || profile == null) return null;

  final loader = MealPlanLoader.instance;
  await loader.preload();
  if (loader.engine.foods.isEmpty) return null; // 食材库空也走空态

  return loader.engine.generate(profile: profile, budget: budget, days: days);
});

/// 保存档案后统一刷新这一串。
///
/// 传 `ref.invalidate` 进来即可（`Ref` 与 `WidgetRef` 签名一致），
/// 这样页面和 Provider 内部都能复用。
///
/// 为什么显式列出而不是 invalidate 整个容器：避免把无关的经期 Provider 也
/// 打回 loading（会让今日页闪一下骨架）。
void invalidateWeightLossChain(void Function(ProviderOrFamily) invalidate) {
  invalidate(bodyProfileRowProvider);
  invalidate(latestWeightProvider);
  invalidate(weightTrendProvider);
  invalidate(userProfileProvider);
  invalidate(calorieBudgetProvider);
  invalidate(dailyEnergyProvider);
  invalidate(todayEnergyProvider);
  invalidate(exerciseLogsProvider);
  invalidate(foodLibraryProvider);
  invalidate(todayMealLogsProvider);
}
