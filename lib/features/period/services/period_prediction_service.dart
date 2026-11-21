// lib/features/period/services/period_prediction_service.dart
//
// 经期预测（纯 Dart，无 Flutter 依赖，可单测）。
//
// 算法来源：月记 1.0.0 的 libapp.so 中保留了 prediction_service.dart 的符号
// 与 _robustPredict / _predictCycleLength / _predictPeriodLength / _checkCycle
// 等方法名，但**方法体不可还原**。这里按「稳健估计」的工程含义重新实现：
//
//   1) 只用最近 N 个周期（默认 6），更早的参考价值低
//   2) 取中位数作为基准，而不是算术平均 —— 一次 45 天的异常周期不会污染结果
//   3) 剔除与中位数偏差超过 tolerance 的周期，再求均值
//   4) 结果 clamp 到生理合理区间，避免输出荒谬值
//   5) 置信度由「样本量」与「离散度」共同决定，样本少或波动大则调低
//
// 与美柚的差异：美柚端侧用多因素逻辑回归（年龄/BMI/同房时机等 10+ 特征）。
// 那需要大量训练数据；月记的场景是「少量个人数据」，稳健统计更合适。

import 'dart:math' as math;

/// 一个历史周期的输入（与 drift 表解耦，便于单测）。
class CycleInput {
  const CycleInput({
    required this.start,
    this.end,
    this.cycleLength,
    this.periodLength,
  });

  /// 经期第一天。
  final DateTime start;

  /// 经期最后一天。
  final DateTime? end;

  /// 周期长度（天）。为 null 时尝试用 end 推导。
  final int? cycleLength;

  /// 经期天数。为 null 时尝试用 start/end 推导。
  final int? periodLength;

  /// 有效周期长度。
  int? get resolvedCycleLength => cycleLength;

  /// 有效经期天数。
  int? get resolvedPeriodLength {
    if (periodLength != null) return periodLength;
    final e = end;
    if (e == null) return null;
    final d = e.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
    return d > 0 ? d : null;
  }
}

/// 预测结果。
class PeriodPrediction {
  const PeriodPrediction({
    required this.periodStart,
    required this.periodEnd,
    required this.ovulation,
    required this.fertileStart,
    required this.fertileEnd,
    required this.cycleLength,
    required this.periodLength,
    required this.confidence,
    required this.basedOnCycles,
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime ovulation;
  final DateTime fertileStart;
  final DateTime fertileEnd;

  /// 本次采用的周期长度（天）。
  final int cycleLength;

  /// 本次采用的经期天数（天）。
  final int periodLength;

  /// 置信度 0–100。
  final int confidence;

  /// 参与计算的周期数。
  final int basedOnCycles;
}

/// 某一天所处的阶段。
enum CyclePhase {
  menstrual('经期'),
  ovulation('排卵日'),
  fertile('易孕期'),
  normal('普通日');

  const CyclePhase(this.label);
  final String label;
}

class PeriodPredictionService {
  const PeriodPredictionService({
    this.windowSize = 6,
    this.toleranceDays = 7,
    this.minCycleLength = 21,
    this.maxCycleLength = 45,
    this.minPeriodLength = 2,
    this.maxPeriodLength = 10,
    this.lutealPhaseDays = 14,
    this.fertileDaysBefore = 5,
    this.fertileDaysAfter = 1,
  });

  /// 参与计算的最大历史周期数。
  final int windowSize;

  /// 与中位数偏差超过该值的周期视为异常，剔除。
  final int toleranceDays;

  final int minCycleLength;
  final int maxCycleLength;
  final int minPeriodLength;
  final int maxPeriodLength;

  /// 黄体期固定 14 天：排卵日 = 下次经期开始 − 14。
  final int lutealPhaseDays;

  /// 易孕期：排卵前 5 天（精子存活）到排卵后 1 天（卵子存活）。
  final int fertileDaysBefore;
  final int fertileDaysAfter;

  /// 生成预测。历史数据不足（<1 个有效周期）时返回 null。
  ///
  /// [cycles] 需按时间升序或乱序均可，内部会排序。
  /// [today] 用于计算「下一次」经期（若最后一次已过预测日，则顺延）。
  PeriodPrediction? predict(
    List<CycleInput> cycles, {
    DateTime? today,
  }) {
    if (cycles.isEmpty) return null;

    final sorted = [...cycles]..sort((a, b) => a.start.compareTo(b.start));

    // ---- 1) 周期长度 ----
    final lengths = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      final l = sorted[i].resolvedCycleLength;
      if (l != null && l >= minCycleLength && l <= maxCycleLength) {
        lengths.add(l);
      } else if (i + 1 < sorted.length) {
        // 未记录 cycleLength 时，用相邻两次起始日推导
        final derived = sorted[i + 1]
            .start
            .difference(sorted[i].start)
            .inDays;
        if (derived >= minCycleLength && derived <= maxCycleLength) {
          lengths.add(derived);
        }
      }
    }
    if (lengths.isEmpty) return null;

    final recentLengths = lengths.length > windowSize
        ? lengths.sublist(lengths.length - windowSize)
        : lengths;

    final median = _median(recentLengths);
    final kept = recentLengths
        .where((l) => (l - median).abs() <= toleranceDays)
        .toList();
    // 全部被剔除（极端情况）时回退到中位数本身
    final effectiveLengths = kept.isEmpty ? [median] : kept;
    final cycleLength = _clamp(
      _mean(effectiveLengths).round(),
      minCycleLength,
      maxCycleLength,
    );

    // ---- 2) 经期天数 ----
    final periodLengths = sorted
        .map((c) => c.resolvedPeriodLength)
        .whereType<int>()
        .where((d) => d >= minPeriodLength && d <= maxPeriodLength)
        .toList();
    final periodLength = periodLengths.isEmpty
        ? 5 // 无记录时用常见值 5 天
        : _clamp(_median(periodLengths).round(), minPeriodLength, maxPeriodLength);

    // ---- 3) 下一次经期 ----
    final lastStart = _dateOnly(sorted.last.start);
    var nextStart = lastStart.add(Duration(days: cycleLength));
    final refToday = _dateOnly(today ?? DateTime.now());
    // 若预测日已过去（用户漏记），顺延到未来
    while (nextStart.isBefore(refToday)) {
      nextStart = nextStart.add(Duration(days: cycleLength));
    }

    // ---- 4) 排卵与易孕期 ----
    final ovulation = nextStart.subtract(Duration(days: lutealPhaseDays));
    final fertileStart = ovulation.subtract(Duration(days: fertileDaysBefore));
    final fertileEnd = ovulation.add(Duration(days: fertileDaysAfter));

    // ---- 5) 置信度 ----
    final confidence = _confidence(
      sampleCount: effectiveLengths.length,
      dispersion: _meanAbsoluteDeviation(effectiveLengths),
    );

    return PeriodPrediction(
      periodStart: nextStart,
      periodEnd: nextStart.add(Duration(days: periodLength - 1)),
      ovulation: ovulation,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      cycleLength: cycleLength,
      periodLength: periodLength,
      confidence: confidence,
      basedOnCycles: effectiveLengths.length,
    );
  }

  /// 判定某一天属于哪个阶段。
  ///
  /// 优先级：已记录的经期 > 预测经期 > 排卵日 > 易孕期 > 普通日。
  CyclePhase phaseOf(
    DateTime day, {
    required PeriodPrediction? prediction,
    List<CycleInput> recordedCycles = const [],
  }) {
    final d = _dateOnly(day);

    // 1) 已实际记录的经期（最高优先级：事实覆盖预测）
    for (final c in recordedCycles) {
      final start = _dateOnly(c.start);
      final end = c.end == null
          ? start.add(Duration(days: (c.resolvedPeriodLength ?? 5) - 1))
          : _dateOnly(c.end!);
      if (!d.isBefore(start) && !d.isAfter(end)) {
        return CyclePhase.menstrual;
      }
    }

    if (prediction == null) return CyclePhase.normal;

    // 2) 预测经期
    if (!d.isBefore(_dateOnly(prediction.periodStart)) &&
        !d.isAfter(_dateOnly(prediction.periodEnd))) {
      return CyclePhase.menstrual;
    }
    // 3) 排卵日
    if (d == _dateOnly(prediction.ovulation)) return CyclePhase.ovulation;
    // 4) 易孕期
    if (!d.isBefore(_dateOnly(prediction.fertileStart)) &&
        !d.isAfter(_dateOnly(prediction.fertileEnd))) {
      return CyclePhase.fertile;
    }
    return CyclePhase.normal;
  }

  /// 距下次经期还有几天（已开始则为负）。
  int daysUntilNextPeriod(PeriodPrediction p, {DateTime? today}) {
    final ref = _dateOnly(today ?? DateTime.now());
    return _dateOnly(p.periodStart).difference(ref).inDays;
  }

  // ---------------- 统计工具 ----------------

  static int _median(List<int> xs) {
    final s = [...xs]..sort();
    final n = s.length;
    if (n.isOdd) return s[n ~/ 2];
    return ((s[n ~/ 2 - 1] + s[n ~/ 2]) / 2).round();
  }

  static double _mean(List<int> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

  /// 平均绝对偏差（比标准差更抗极端值，与中位数口径一致）。
  static double _meanAbsoluteDeviation(List<int> xs) {
    if (xs.isEmpty) return 0;
    final m = _mean(xs);
    return xs.map((x) => (x - m).abs()).reduce((a, b) => a + b) / xs.length;
  }

  static int _clamp(int v, int lo, int hi) => math.min(math.max(v, lo), hi);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// 置信度：样本量给基础分，离散度扣分。
  static int _confidence({
    required int sampleCount,
    required double dispersion,
  }) {
    const base = {1: 25, 2: 40, 3: 55, 4: 70, 5: 80};
    final baseScore = sampleCount >= 6 ? 90 : (base[sampleCount] ?? 25);
    // 每天偏差扣 4 分，最多扣 40
    final penalty = math.min((dispersion * 4).round(), 40);
    return (baseScore - penalty).clamp(5, 95);
  }
}
