// lib/features/period/services/period_history_editor.dart
//
// 补记/编辑历史经期的**纯逻辑层**（P4-1）。
//
// 为什么单独抽一个纯函数：补记最容易写坏的是「周期长度」。
// 领域定义是
//     周期长度 = 下次经期开始日 − 本次经期开始日
// 所以往中间插一段历史经期，会同时改变**它自己**和**它前一段**的 cycleLength；
// 往前插还会把原本 open 的周期变成 closed。这些关系必须能被单测逐条锁住，
// 不能埋在 UI 或 DB 事务里靠人眼验证。
//
// 本文件不含 drift / Flutter 依赖：输入输出都是 CycleInput，
// 仓库层负责把结果写回库（含 daily_records 的经期日标记）。

import 'period_prediction_service.dart';

/// 补记结果。
class PeriodEditResult {
  const PeriodEditResult._({
    required this.cycles,
    required this.periodDays,
    this.error,
  });

  factory PeriodEditResult.ok({
    required List<CycleInput> cycles,
    required Set<DateTime> periodDays,
  }) =>
      PeriodEditResult._(cycles: cycles, periodDays: periodDays);

  factory PeriodEditResult.failed(String reason) =>
      PeriodEditResult._(cycles: const [], periodDays: const {}, error: reason);

  /// 重算后的周期表（按开始日升序）。
  final List<CycleInput> cycles;

  /// 所有应被标记为「经期日」的日期（全量，供仓库重建 daily_records）。
  final Set<DateTime> periodDays;

  /// 失败原因（人类可读）；null 表示成功。
  final String? error;

  bool get ok => error == null;
}

class PeriodHistoryEditor {
  const PeriodHistoryEditor();

  /// 最少/最大经期长度（与预测服务的生理区间保持一致）。
  static const int minPeriodLength = 2;
  static const int maxPeriodLength = 10;

  /// 两次经期开始日之间的最小间隔。
  ///
  /// 来源：美柚 `RecordMenstrualActivity.v()` 的校验 —— 与已有经期开始日
  /// 相差 `abs < 15` 天时直接拒绝并提示「经期时间间隔太短」；
  /// `MenstrualTimeManager.h()` 同样以 ±15 天为窗口做「就近合并」。
  /// 端侧照抄这条规则的理由：没有它，用户手滑就能补出 3 天周期的荒谬数据，
  /// 而周期长度是预测的唯一输入，一条脏数据会污染后面所有预测。
  static const int minGapDays = 15;

  /// 把一段历史经期（[start] + 可选 [end]）合并进 [existing]。
  ///
  /// 规则：
  ///   · [start] 不能晚于 [today]（不允许补记未来）；
  ///   · [end] 不能早于 [start]，长度需在 [minPeriodLength, maxPeriodLength]；
  ///   · 与已有周期**重叠**（开始日落在别人的经期区间内）时拒绝，
  ///     不做"自动合并"——合并会悄悄改掉用户已录的经期天数；
  ///   · 同一开始日视为编辑该周期（改结束日）；
  ///   · 结果按开始日升序，cycleLength 全部重算（见文件头）。
  PeriodEditResult upsert({
    required List<CycleInput> existing,
    required DateTime start,
    DateTime? end,
    DateTime? today,
  }) {
    final s = _dateOnly(start);
    final e = end == null ? null : _dateOnly(end);
    final t = _dateOnly(today ?? DateTime.now());

    if (s.isAfter(t)) {
      return PeriodEditResult.failed('不能补记未来的经期');
    }
    if (e != null) {
      if (e.isBefore(s)) {
        return PeriodEditResult.failed('结束日不能早于开始日');
      }
      if (e.isAfter(t)) {
        return PeriodEditResult.failed('结束日不能是未来日期');
      }
      final len = e.difference(s).inDays + 1;
      if (len < minPeriodLength) {
        return PeriodEditResult.failed('经期至少 $minPeriodLength 天');
      }
      if (len > maxPeriodLength) {
        return PeriodEditResult.failed('经期最长 $maxPeriodLength 天，请检查日期');
      }
    }

    // 已有周期区间：用于重叠检测（同 start 的不算重叠，那是编辑）
    for (final c in existing) {
      final cs = _dateOnly(c.start);
      if (cs == s) continue;

      // 美柚规则：开始日间隔不足 15 天即视为误触（见 minGapDays 注释）
      final gap = cs.difference(s).inDays.abs();
      if (gap < minGapDays) {
        return PeriodEditResult.failed(
          '两次经期开始日至少隔 $minGapDays 天（与 ${cs.month}月${cs.day}日 只差 $gap 天）',
        );
      }

      final ce = c.end == null
          ? cs.add(Duration(days: (c.resolvedPeriodLength ?? 5) - 1))
          : _dateOnly(c.end!);
      final overlaps = !s.isAfter(ce) && !(e ?? s).isBefore(cs);
      if (overlaps) {
        return PeriodEditResult.failed(
          '这段日期与 ${cs.month}月${cs.day}日 开始的经期重叠',
        );
      }
    }

    // 合并：同 start 覆盖，否则插入
    final merged = <CycleInput>[];
    var replaced = false;
    for (final c in existing) {
      if (_dateOnly(c.start) == s) {
        merged.add(CycleInput(start: s, end: e));
        replaced = true;
      } else {
        merged.add(CycleInput(
          start: _dateOnly(c.start),
          end: c.end == null ? null : _dateOnly(c.end!),
        ));
      }
    }
    if (!replaced) {
      merged.add(CycleInput(start: s, end: e));
    }

    merged.sort((a, b) => a.start.compareTo(b.start));

    // 重算：cycleLength 由下一段的开始日决定；最后一段没有下一段则留空
    final recalculated = <CycleInput>[];
    for (var i = 0; i < merged.length; i++) {
      final cur = merged[i];
      final next = i + 1 < merged.length ? merged[i + 1] : null;
      final curEnd = cur.end;
      final cycleLength = next?.start.difference(cur.start).inDays;
      int? periodLength;
      if (curEnd != null) {
        periodLength = curEnd.difference(cur.start).inDays + 1;
      }
      recalculated.add(CycleInput(
        start: cur.start,
        end: cur.end,
        cycleLength: cycleLength,
        periodLength: periodLength,
      ));
    }

    return PeriodEditResult.ok(
      cycles: recalculated,
      periodDays: _periodDaysOf(recalculated),
    );
  }

  /// 删除从 [start] 开始的那一段（纠错用）。返回删除后的周期表。
  PeriodEditResult remove({
    required List<CycleInput> existing,
    required DateTime start,
  }) {
    final s = _dateOnly(start);
    final kept = existing
        .where((c) => _dateOnly(c.start) != s)
        .map((c) => CycleInput(
              start: _dateOnly(c.start),
              end: c.end == null ? null : _dateOnly(c.end!),
            ))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    if (kept.length == existing.length) {
      return PeriodEditResult.failed('没有找到这段经期');
    }

    final recalculated = <CycleInput>[];
    for (var i = 0; i < kept.length; i++) {
      final cur = kept[i];
      final next = i + 1 < kept.length ? kept[i + 1] : null;
      final curEnd = cur.end;
      recalculated.add(CycleInput(
        start: cur.start,
        end: cur.end,
        cycleLength: next?.start.difference(cur.start).inDays,
        periodLength: curEnd == null ? null : (curEnd.difference(cur.start).inDays + 1),
      ));
    }

    return PeriodEditResult.ok(
      cycles: recalculated,
      periodDays: _periodDaysOf(recalculated),
    );
  }

  /// 找出 [day] 落在哪一段经期里；不在任何经期内返回 null。
  ///
  /// 未结束的经期按「开始日 + 已记录天数（默认 5）」估算区间，
  /// 与 `phaseOf` 的判定口径一致，避免两处给出不同答案。
  CycleInput? cycleAt(List<CycleInput> cycles, DateTime day) {
    final d = _dateOnly(day);
    for (final c in cycles) {
      final s = _dateOnly(c.start);
      final e = c.end == null
          ? s.add(Duration(days: (c.resolvedPeriodLength ?? 5) - 1))
          : _dateOnly(c.end!);
      if (!d.isBefore(s) && !d.isAfter(e)) return c;
    }
    return null;
  }

  Set<DateTime> _periodDaysOf(List<CycleInput> cycles) {
    final days = <DateTime>{};
    for (final c in cycles) {
      final s = _dateOnly(c.start);
      final e = c.end == null
          ? s.add(Duration(days: (c.resolvedPeriodLength ?? 5) - 1))
          : _dateOnly(c.end!);
      var d = s;
      while (!d.isAfter(e)) {
        days.add(d);
        d = d.add(const Duration(days: 1));
      }
    }
    return days;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
