// lib/features/period/services/pregnancy_odds_service.dart
//
// 怀孕几率估算。**算法逐行移植自月记 1.0.0 的 assets/pregnancyOdds.js**
// —— 那份 JS 是明文，可直接读取，因此这里的系数与原版完全一致。
//
// 原实现（pregnancyOdds.js）：
//   易孕期逐日基础概率 easyDay = [0.35,0.4,0.55,0.65,0.8,0.9,0.8,0.75,0.65,0.5]
//   月经期 0.1 / 安全期 0.15 / 排卵日 0.9
//   避孕修正：安全套 0.01、避孕药 0.02、体外 0.05、无措施 1.0
//   多次同房：1 − Π(1 − p_i)
//   边界收敛：100 → 99，0 → 1
//
// 字段名说明：原 JS 的 is_safety_measure 在源码注释里就是「无措施」，
// 命名容易误解，这里改名为 hadUnprotected。
//
// ⚠️ 本结果仅供参考，不构成避孕建议。

import 'dart:math' as math;

/// 与预测阶段对应（与原 JS 的 period 1..4 一一映射）。
enum OddsPhase {
  /// 原 period = 1
  menstrual,

  /// 原 period = 2
  safe,

  /// 原 period = 3
  fertile,

  /// 原 period = 4
  ovulation,
}

/// 一次同房记录。
class IntercourseRecord {
  const IntercourseRecord({
    this.hadUnprotected = false,
    this.usedCondom = false,
    this.takenBirthControlPill = false,
    this.withdrawal = false,
  });

  /// 原 is_safety_measure：「无措施」。
  final bool hadUnprotected;

  /// 原 is_used_condom：安全套。
  final bool usedCondom;

  /// 原 is_taken_birth_control_pill：紧急避孕药。
  final bool takenBirthControlPill;

  /// 原 is_outside_spermiation：体外排精。
  final bool withdrawal;
}

class PregnancyOddsService {
  const PregnancyOddsService();

  /// 易孕期逐日基础概率（第 1..10 天）。原样保留。
  static const List<double> easyDayOdds = [
    0.35,
    0.4,
    0.55,
    0.65,
    0.8,
    0.9,
    0.8,
    0.75,
    0.65,
    0.5,
  ];

  static const double _menstrualOdd = 0.1;
  static const double _safeOdd = 0.15;
  static const double _ovulationOdd = 0.9;

  static const double _coeffNone = 1.0;
  static const double _coeffWithdrawal = 0.05;
  static const double _coeffPill = 0.02;
  static const double _coeffCondom = 0.01;
  static const double _coeffFallback = 0.02;

  /// 计算当日怀孕几率（百分比，0–99）。
  ///
  /// [easyDayIndex] 为易孕期第几天（1–10），仅 [OddsPhase.fertile] 时使用；
  /// 超出范围返回 0（与原 JS 的 `if(easyDay > 10) return 0` 一致）。
  double calculate({
    required OddsPhase phase,
    int? easyDayIndex,
    List<IntercourseRecord> records = const [],
  }) {
    // ---- 自然概率 ----
    double natureOdd;
    switch (phase) {
      case OddsPhase.menstrual:
        natureOdd = _menstrualOdd;
      case OddsPhase.safe:
        natureOdd = _safeOdd;
      case OddsPhase.fertile:
        final idx = easyDayIndex ?? 0;
        if (idx < 1 || idx > 10) return 0;
        natureOdd = easyDayOdds[idx - 1];
      case OddsPhase.ovulation:
        natureOdd = _ovulationOdd;
    }

    // ---- 无同房记录：只返回自然概率（原 JS 提前 return，不做边界收敛） ----
    if (records.isEmpty) return natureOdd * 100;

    double result;

    if (records.length == 1) {
      final r = records.first;
      var coeff = _coeffNone;
      if (r.withdrawal) coeff = _coeffWithdrawal;
      if (r.takenBirthControlPill) coeff = _coeffPill;
      if (r.usedCondom) coeff = _coeffCondom;
      result = _round2(natureOdd * coeff) * 100;
    } else {
      // 当天只要有一次服用了避孕药 → 除安全套外全部按 0.02
      final usedPill = records.any((r) => r.takenBirthControlPill);

      final odds = <double>[];
      for (final r in records) {
        var coeff = _coeffFallback;
        if (r.hadUnprotected && !usedPill) coeff = _coeffNone;
        if (r.withdrawal && !usedPill) coeff = _coeffWithdrawal;
        if (r.takenBirthControlPill && !usedPill) coeff = _coeffPill;
        if (r.usedCondom) coeff = _coeffCondom;
        odds.add(natureOdd * coeff);
      }

      // 多次同房「都不怀孕」的概率相乘，再取补
      var notPregnant = 1.0;
      for (final p in odds) {
        notPregnant *= (1 - p);
      }
      result = _round2(1 - notPregnant) * 100;
    }

    // 边界收敛：100 → 99，0 → 1
    if (result == 100) return 99;
    if (result == 0) return 1;
    return result;
  }

  /// 原 JS 的 forDight(x, 2)：四舍五入到 2 位小数。
  static double _round2(double v) =>
      (v * math.pow(10, 2)).roundToDouble() / math.pow(10, 2);
}
