// lib/features/period/data/period_tables.dart
//
// 经期模块数据表。
//
// 字段来源：对月记 1.0.0 的 libapp.so 逆向提取（drift 生成的 SQL 约束片段可读出
// 真实列名与 CHECK）。原始约束：
//   CHECK ("is_closed" IN (0, 1))
//   CHECK ("is_period_day" IN (0, 1))
//   CHECK ("sexual_activity" IN (0, 1))
// 这里用 drift 的 boolean() 表达，底层同为 INTEGER 0/1。
//
// 设计说明：
//   · DailyRecords 以 date 为主键 —— 一天只有一条汇总记录，多指标都挂在这条上
//   · symptoms 存 JSON 数组字符串（如 ["头痛","失眠"]），二期可拆表
//   · PredictionCaches 独立成表：预测可复现、可解释、可失效重算

import 'package:drift/drift.dart';

/// 一个完整月经周期。
class PeriodCycles extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 周期内经期的第一天。
  DateTimeColumn get startDate => dateTime()();

  /// 经期最后一天（未结束为 null）。
  DateTimeColumn get endDate => dateTime().nullable()();

  /// 本周期长度（天）；周期结束后回填。
  IntColumn get cycleLength => integer().nullable()();

  /// 本周期经期天数；结束前为 null。
  IntColumn get periodLength => integer().nullable()();

  /// 周期是否已结束。对应原库 is_closed。
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 每日记录。一天一条，主键为 date。
class DailyRecords extends Table {
  /// 记录日期（本地时区零点）。主键。
  DateTimeColumn get date => dateTime()();

  /// 经量等级（0=无 1=少 2=中 3=多），见 FlowLevel。
  IntColumn get flowLevel => integer().nullable()();

  /// 痛经等级（0–3），见 PainLevel。
  IntColumn get painLevel => integer().nullable()();

  /// 心情代码，对应 assets 的 feelings.json 的 id。
  TextColumn get mood => text().nullable()();

  /// 症状代码数组，JSON 字符串。对应 all_symptom_data.json 的 id。
  TextColumn get symptoms => text().nullable()();

  TextColumn get note => text().nullable()();

  RealColumn get weightKg => real().nullable()();

  /// 是否有性生活（原库 CHECK 0/1）。**敏感字段，禁止写日志。**
  BoolColumn get sexualActivity =>
      boolean().withDefault(const Constant(false))();

  /// 是否经期日。日状态判定的关键字段。
  BoolColumn get isPeriodDay => boolean().withDefault(const Constant(false))();

  /// 血色（褐色 / 鲜红 / 暗红），存枚举名。
  TextColumn get bloodColor => text().nullable()();

  RealColumn get sleepHours => real().nullable()();

  /// 归属周期。为空表示尚未归入任何周期。
  IntColumn get cycleId => integer().nullable()();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {date};
}

/// 预测结果缓存。基于 N 个周期算出的下一次预测。
class PredictionCaches extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get predictedPeriodStart => dateTime()();
  DateTimeColumn get predictedPeriodEnd => dateTime()();
  DateTimeColumn get predictedOvulationDate => dateTime().nullable()();
  DateTimeColumn get fertileStart => dateTime().nullable()();
  DateTimeColumn get fertileEnd => dateTime().nullable()();

  /// 置信度 0–100。样本越少、波动越大，值越低。
  IntColumn get confidenceLevel => integer()();

  /// 本次预测基于多少个历史周期。
  IntColumn get basedOnCycles => integer()();

  DateTimeColumn get generatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// 经量等级。与 UI 下拉项一一对应。
enum FlowLevel {
  none(0, '无'),
  light(1, '少'),
  medium(2, '中'),
  heavy(3, '多');

  const FlowLevel(this.value, this.label);
  final int value;
  final String label;

  static FlowLevel fromValue(int? v) {
    for (final e in FlowLevel.values) {
      if (e.value == v) return e;
    }
    return FlowLevel.none;
  }
}

/// 痛经等级。
enum PainLevel {
  none(0, '无'),
  mild(1, '轻微'),
  moderate(2, '明显'),
  severe(3, '严重');

  const PainLevel(this.value, this.label);
  final int value;
  final String label;

  static PainLevel fromValue(int? v) {
    for (final e in PainLevel.values) {
      if (e.value == v) return e;
    }
    return PainLevel.none;
  }
}

/// 血色。原库为文本枚举。
enum BloodColor {
  brown('褐色'),
  brightRed('鲜红'),
  darkRed('暗红');

  const BloodColor(this.label);
  final String label;
}
