// lib/features/weight_loss/data/weight_loss_tables.dart
//
// drift 表定义。接入方式：把这些类加入你现有的
// data/local/database/tables.dart，并在 AppDatabase 的
// @DriftDatabase(tables: [...]) 里追加，然后跑 build_runner。
//
//   dart run build_runner build --delete-conflicting-outputs
//
// 迁移：在 AppDatabase 的 migration 里加 schemaVersion 判断。

import 'package:drift/drift.dart';

/// 体重记录。一天允许多条（早晚各称一次），由 UI 取当日最后一条作为"当日体重"。
class WeightLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get weightKg => real()();
  RealColumn get bodyFatPercent => real().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        // 同一天同一时刻只允许一条，避免重复提交
        {recordedAt},
      ];
}

/// 运动记录。met 与 name 做冗余存储——历史记录不能因为
/// 以后改了 MET 表就失真。
class ExerciseLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get exerciseCode => text()();
  TextColumn get exerciseName => text()();
  RealColumn get met => real()();
  IntColumn get minutes => integer()();

  /// 记录当时的体重，用于复盘"同样运动为什么消耗变了"
  RealColumn get weightKgAtTime => real()();

  /// 计算出的消耗（冗余存储，保证历史可复现）
  RealColumn get kcal => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 饮食记录。grams 与 kcal 都存，便于按"份"或按"克"两种习惯记录。
class MealLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();

  /// breakfast / lunch / dinner / snack
  TextColumn get mealType => text()();
  TextColumn get foodCode => text()();
  TextColumn get foodName => text()();
  RealColumn get grams => real()();
  RealColumn get kcal => real()();
  RealColumn get proteinG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real().withDefault(const Constant(0))();
  RealColumn get carbG => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 用户身体档案（单行表，id 固定为 1）。
class BodyProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// male / female
  TextColumn get sex => text()();
  IntColumn get age => integer()();
  RealColumn get heightCm => real()();
  RealColumn get startWeightKg => real()();

  /// sedentary / light / moderate / active / veryActive
  TextColumn get activityLevel => text()();

  /// 体脂率（%）。null = 用户没填。
  ///
  /// 填了之后 TdeeService 会改用 Katch-McArdle（基于去脂体重），
  /// 对体脂偏高/偏低的人比 Mifflin-St Jeor 更准。
  /// 加列时间：schema v4（只 addColumn，不动老数据）。
  RealColumn get bodyFatPercent => real().nullable()();

  RealColumn get targetWeightKg => real().nullable()();

  /// lose / maintain / gain
  TextColumn get goal => text().withDefault(const Constant('lose'))();

  /// gentle / standard / aggressive
  TextColumn get pace => text().withDefault(const Constant('standard'))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 用户自建食物（P2-3 第 4 步，必做）。
///
/// 为什么必须有这张表：seed_foods.json 只有 42 种，用户吃的东西远不止这些。
/// 如果不能自建，用户搜不到就只能放弃记录 —— 而记录是这个模块的命根子。
///
/// code 规则：`custom_` 前缀 + 毫秒时间戳，避免与种子库撞码。
/// 营养值按每 100 g 存，与 FoodItem 的口径完全一致。
class CustomFoods extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 全局唯一标识，格式 custom_<毫秒时间戳>
  TextColumn get code => text().unique()();
  TextColumn get name => text().withLength(min: 1, max: 30)();
  RealColumn get kcalPer100g => real()();
  RealColumn get proteinPer100g => real().withDefault(const Constant(0))();
  RealColumn get fatPer100g => real().withDefault(const Constant(0))();
  RealColumn get carbPer100g => real().withDefault(const Constant(0))();

  /// 一份的克数与名称（如 1 个 ≈ 50 g），默认 100 g / 份
  RealColumn get unitGrams => real().withDefault(const Constant(100))();
  TextColumn get unitName => text().withDefault(const Constant('份'))();

  /// staple / protein / vegetable / fruit / dairy / fat / custom
  TextColumn get category => text().withDefault(const Constant('custom'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// 每日热量预算快照。预算会随体重变化，按天留存便于回看"那天为什么只给我 1500 kcal"。
///
/// 显式指定数据类名：默认会生成 `CalorieBudget`，与领域模型
/// weight_loss_models.dart 中的 CalorieBudget 重名，导致 ambiguous_import。
@DataClassName('CalorieBudgetRow')
class CalorieBudgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get bmr => real()();
  RealColumn get tdee => real()();
  RealColumn get intakeTarget => real()();
  RealColumn get proteinG => real()();
  RealColumn get fatG => real()();
  RealColumn get carbG => real()();
  TextColumn get formula => text().withDefault(const Constant('Mifflin-St Jeor'))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {date},
      ];
}
