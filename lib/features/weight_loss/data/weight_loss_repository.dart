// lib/features/weight_loss/data/weight_loss_repository.dart
//
// 数据访问层。假定你现有的 drift 数据库类名为 AppDatabase，
// 且已在 @DriftDatabase(tables: [...]) 中注册本模块的 5 张表。
// 若类名不同，改这里的 import 与类型即可。
//
// 重点实现两个「分析型」能力，这是留存的关键：
//   1) 体重趋势 = 7 日移动平均（原始体重波动 ±1kg 是正常的，直接画折线会很吓人）
//   2) 每日净热量 = 摄入 − 运动消耗，对比预算给出「今日余额」

import 'package:drift/drift.dart';

import '../../../data/local/database/app_database.dart';
import '../models/weight_loss_models.dart';
import '../services/exercise_service.dart' show ExerciseDef;

/// 体重趋势点
class WeightPoint {
  const WeightPoint({required this.date, required this.raw, required this.trend});
  final DateTime date;

  /// 当日原始体重（取当日最后一条）
  final double raw;

  /// 7 日移动平均
  final double trend;
}

/// 每日热量概况
class DailyEnergySummary {
  const DailyEnergySummary({
    required this.date,
    required this.intakeKcal,
    required this.burnKcal,
    required this.budgetKcal,
  });

  final DateTime date;
  final double intakeKcal;
  final double burnKcal;
  final double budgetKcal;

  /// 还可吃多少（正数=余额，负数=超出）
  double get remainKcal => budgetKcal - intakeKcal + burnKcal;

  bool get isOver => remainKcal < 0;
}

/// 热量趋势的单日数据点（P2-4）。只含有记录的日子。
class EnergyPoint {
  const EnergyPoint({
    required this.date,
    required this.intakeKcal,
    required this.burnKcal,
  });
  final DateTime date;
  final double intakeKcal;
  final double burnKcal;
}

class WeightLossRepository {
  WeightLossRepository(this._db);
  final AppDatabase _db;

  // ---------- 档案 ----------

  Future<BodyProfile?> profile() =>
      (_db.select(_db.bodyProfiles)..limit(1)).getSingleOrNull();

  /// 保存档案。
  ///
  /// [preserveStartWeight] 为 true 时沿用库里已有的起始体重（编辑场景）。
  /// 为什么需要这个开关：startWeightKg 的语义是「建档案那天多重」，
  /// 用户半年后改一次身高，不该把起始体重改成今天的体重，
  /// 否则「累计减了多少」这个指标会被抹掉。
  Future<void> saveProfile(
    UserProfile p, {
    bool preserveStartWeight = false,
  }) async {
    var start = p.weightKg;
    if (preserveStartWeight) {
      final existing = await profile();
      start = existing?.startWeightKg ?? p.weightKg;
    }

    await _db.into(_db.bodyProfiles).insertOnConflictUpdate(
          BodyProfilesCompanion.insert(
            id: const Value(1),
            sex: p.sex.name,
            age: p.age,
            heightCm: p.heightCm,
            startWeightKg: start,
            activityLevel: p.activity.name,
            targetWeightKg: Value(p.targetWeightKg),
            goal: Value(p.goal.name),
            pace: Value(p.pace.name),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  // ---------- 体重 ----------

  Future<void> addWeight({
    required double weightKg,
    double? bodyFatPercent,
    DateTime? at,
    String note = '',
  }) async {
    await _db.into(_db.weightLogs).insert(
          WeightLogsCompanion.insert(
            recordedAt: at ?? DateTime.now(),
            weightKg: weightKg,
            bodyFatPercent: Value(bodyFatPercent),
            note: Value(note),
          ),
        );
  }

  /// 取最近 [days] 天的体重趋势（含 7 日移动平均）
  Future<List<WeightPoint>> weightTrend({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days + 7));
    final rows = await (_db.select(_db.weightLogs)
          ..where((t) => t.recordedAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm.asc(t.recordedAt)]))
        .get();

    // 按天聚合：一天多条取最后一条
    final byDay = <DateTime, double>{};
    for (final r in rows) {
      final d = DateTime(r.recordedAt.year, r.recordedAt.month, r.recordedAt.day);
      byDay[d] = r.weightKg; // 顺序遍历，后面的自然覆盖前面的
    }
    final dates = byDay.keys.toList()..sort();
    if (dates.isEmpty) return const [];

    final points = <WeightPoint>[];
    for (var i = 0; i < dates.length; i++) {
      // 7 日窗口（不足 7 天就用已有数据，避免前几天没有趋势线）
      final from = i - 6 < 0 ? 0 : i - 6;
      var sum = 0.0;
      var n = 0;
      for (var j = from; j <= i; j++) {
        sum += byDay[dates[j]]!;
        n++;
      }
      points.add(WeightPoint(
        date: dates[i],
        raw: byDay[dates[i]]!,
        trend: sum / n,
      ));
    }
    return points;
  }

  Future<double?> latestWeight() async {
    final row = await (_db.select(_db.weightLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.weightKg;
  }

  // ---------- 运动 ----------

  /// 最近 [days] 天的运动记录（倒序）。
  Future<List<ExerciseLog>> exerciseLogs({int days = 90}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    return (_db.select(_db.exerciseLogs)
          ..where((t) => t.recordedAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
  }

  Future<void> addExercise({
    required ExerciseDef def,
    required int minutes,
    required double weightKg,
    DateTime? at,
  }) async {
    final kcal = ExerciseServiceKcal.burn(
      met: def.met,
      weightKg: weightKg,
      minutes: minutes,
    );
    await _db.into(_db.exerciseLogs).insert(
          ExerciseLogsCompanion.insert(
            recordedAt: at ?? DateTime.now(),
            exerciseCode: def.code,
            exerciseName: def.name,
            met: def.met,
            minutes: minutes,
            weightKgAtTime: weightKg,
            kcal: kcal,
          ),
        );
  }

  // ---------- 饮食 ----------

  /// 最近 [days] 天的每日摄入/运动消耗序列（升序）。
  ///
  /// 供趋势页（P2-4）用：按天聚合 mealLogs.kcal 与 exerciseLogs.kcal，
  /// **只返回有记录的日子** —— 没记的那天画 0 会把"没记"误读成"吃了 0"，
  /// 趋势图的口径必须是"记了多少算多少"。
  Future<List<EnergyPoint>> dailyEnergySeries({int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final start = DateTime(since.year, since.month, since.day);

    final meals = await (_db.select(_db.mealLogs)
          ..where((t) => t.recordedAt.isBiggerOrEqualValue(start)))
        .get();
    final exercises = await (_db.select(_db.exerciseLogs)
          ..where((t) => t.recordedAt.isBiggerOrEqualValue(start)))
        .get();

    final intakeByDay = <DateTime, double>{};
    for (final m in meals) {
      final d = DateTime(m.recordedAt.year, m.recordedAt.month, m.recordedAt.day);
      intakeByDay[d] = (intakeByDay[d] ?? 0) + m.kcal;
    }
    final burnByDay = <DateTime, double>{};
    for (final e in exercises) {
      final d = DateTime(e.recordedAt.year, e.recordedAt.month, e.recordedAt.day);
      burnByDay[d] = (burnByDay[d] ?? 0) + e.kcal;
    }

    final dates = <DateTime>{...intakeByDay.keys, ...burnByDay.keys}.toList()
      ..sort();
    return [
      for (final d in dates)
        EnergyPoint(
          date: d,
          intakeKcal: intakeByDay[d] ?? 0,
          burnKcal: burnByDay[d] ?? 0,
        ),
    ];
  }

  /// 某天的饮食记录（按时间倒序）。
  Future<List<MealLog>> mealLogs({DateTime? day}) async {
    final query = _db.select(_db.mealLogs);
    if (day != null) {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      query.where((t) =>
          t.recordedAt.isBiggerOrEqualValue(start) &
          t.recordedAt.isSmallerThanValue(end));
    }
    query.orderBy([(t) => OrderingTerm.desc(t.recordedAt)]);
    return query.get();
  }

  /// 删除一条饮食记录（记错的时候用）。
  Future<void> deleteMeal(int id) async {
    await (_db.delete(_db.mealLogs)..where((t) => t.id.equals(id))).go();
  }

  /// 删除一条运动记录（记错了要能删，和饮食同口径）。
  Future<void> deleteExercise(int id) async {
    await (_db.delete(_db.exerciseLogs)..where((t) => t.id.equals(id))).go();
  }

  Future<void> addMeal({
    required String mealType,
    required FoodItem food,
    required double grams,
    DateTime? at,
  }) async {
    final f = grams / 100.0;
    await _db.into(_db.mealLogs).insert(
          MealLogsCompanion.insert(
            recordedAt: at ?? DateTime.now(),
            mealType: mealType,
            foodCode: food.code,
            foodName: food.name,
            grams: grams,
            kcal: food.kcalPer100g * f,
            proteinG: Value(food.proteinPer100g * f),
            fatG: Value(food.fatPer100g * f),
            carbG: Value(food.carbPer100g * f),
          ),
        );
  }

  // ---------- 自建食物 ----------

  /// 全部自建食物（按创建时间倒序）。
  Future<List<CustomFood>> customFoods() async {
    return (_db.select(_db.customFoods)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// 新建/更新自建食物，返回入库后的完整 FoodItem。
  ///
  /// [code] 为空表示新建：自动生成 `custom_<毫秒>` 编码。
  /// 传入已有 code 则整体覆盖（编辑场景）。
  Future<FoodItem> saveCustomFood({
    required String name,
    required double kcalPer100g,
    double proteinPer100g = 0,
    double fatPer100g = 0,
    double carbPer100g = 0,
    double unitGrams = 100,
    String unitName = '份',
    String? code,
  }) async {
    final resolvedCode =
        code ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';

    // 不能用 insertOnConflictUpdate：它只认主键 id 冲突，
    // 而 code 的 unique 约束冲突会直接抛异常。所以先按 code 查，
    // 有就更新那一行，没有才插入。
    final existing = await (_db.select(_db.customFoods)
          ..where((t) => t.code.equals(resolvedCode))
          ..limit(1))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.customFoods).insert(
            CustomFoodsCompanion.insert(
              code: resolvedCode,
              name: name,
              kcalPer100g: kcalPer100g,
              proteinPer100g: Value(proteinPer100g),
              fatPer100g: Value(fatPer100g),
              carbPer100g: Value(carbPer100g),
              unitGrams: Value(unitGrams),
              unitName: Value(unitName),
            ),
          );
    } else {
      await (_db.update(_db.customFoods)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        CustomFoodsCompanion(
          name: Value(name),
          kcalPer100g: Value(kcalPer100g),
          proteinPer100g: Value(proteinPer100g),
          fatPer100g: Value(fatPer100g),
          carbPer100g: Value(carbPer100g),
          unitGrams: Value(unitGrams),
          unitName: Value(unitName),
        ),
      );
    }

    return FoodItem(
      code: resolvedCode,
      name: name,
      kcalPer100g: kcalPer100g,
      proteinPer100g: proteinPer100g,
      fatPer100g: fatPer100g,
      carbPer100g: carbPer100g,
      category: 'custom',
      unitGrams: unitGrams,
      unitName: unitName,
    );
  }

  // ---------- 汇总 ----------

  /// 某天的热量概况
  Future<DailyEnergySummary> summaryOf(DateTime day, CalorieBudget budget) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final meals = await (_db.select(_db.mealLogs)
          ..where((t) =>
              t.recordedAt.isBiggerOrEqualValue(start) &
              t.recordedAt.isSmallerThanValue(end)))
        .get();
    final ex = await (_db.select(_db.exerciseLogs)
          ..where((t) =>
              t.recordedAt.isBiggerOrEqualValue(start) &
              t.recordedAt.isSmallerThanValue(end)))
        .get();

    return DailyEnergySummary(
      date: start,
      intakeKcal: meals.fold(0.0, (s, r) => s + r.kcal),
      burnKcal: ex.fold(0.0, (s, r) => s + r.kcal),
      budgetKcal: budget.intakeTarget,
    );
  }
}

/// 独立出的小工具，避免 repository 依赖 ExerciseService 的静态方法名
class ExerciseServiceKcal {
  static double burn({
    required double met,
    required double weightKg,
    required int minutes,
  }) =>
      met * 3.5 * weightKg / 200.0 * minutes;
}
