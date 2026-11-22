// lib/features/period/data/period_repository.dart
//
// 经期记录的数据访问层。
//
// 领域规则（很重要，写错会导致周期长度算错）：
//   一次「月经周期」= 从本次经期第一天，到下次经期开始前一天。
//   因此：
//     · 点「经期开始」= 结束上一个周期（回填 cycleLength + isClosed）并开启新周期
//     · 点「经期结束」= 只回填 endDate / periodLength（经期长度），**不代表周期结束**
//   这两个概念在库里是两个字段，不要混。
//
// 所有日期一律先归一化到本地零点（_dateOnly），避免时分秒参与比较导致差一天。

import 'package:drift/drift.dart';

import '../../../data/local/database/app_database.dart';
import '../services/period_history_editor.dart';
import '../services/period_prediction_service.dart';

class PeriodRepository {
  PeriodRepository(this._db, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final AppDatabase _db;

  /// 「今天」的唯一来源。
  ///
  /// 为什么要可注入：补记/删除历史经期时会按「今天」裁掉未来日期，
  /// 若直接调 `DateTime.now()`，测试只能把期望值跟着真实日期漂移
  /// （2026-11-22 就因此红过两条：期望 56 天，实际 57 天）。
  /// 生产代码不传，等价于 `DateTime.now`。
  final DateTime Function() _now;

  // ---------------- 读 ----------------

  /// 按开始时间升序返回所有周期（映射为纯数据对象，供预测算法使用）。
  Future<List<CycleInput>> loadCycles() async {
    final rows = await (_db.select(_db.periodCycles)
          ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
        .get();

    return rows
        .map((r) => CycleInput(
              start: r.startDate,
              end: r.endDate,
              cycleLength: r.cycleLength,
              periodLength: r.periodLength,
            ))
        .toList(growable: false);
  }

  /// 最近一个未关闭的周期（= 当前正在进行的周期）。
  Future<PeriodCycle?> openCycle() async {
    final rows = await (_db.select(_db.periodCycles)
          ..where((t) => t.isClosed.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  /// 某天的记录。
  Future<DailyRecord?> recordOf(DateTime date) async {
    final d = _dateOnly(date);
    return (_db.select(_db.dailyRecords)
          ..where((t) => t.date.equals(d))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 指定日期是否处于「经期中」（已记录的经期区间内）。
  Future<bool> isInPeriod(DateTime date) async {
    final d = _dateOnly(date);
    final cycles = await loadCycles();
    for (final c in cycles) {
      final start = _dateOnly(c.start);
      final end = c.end == null
          ? null
          : _dateOnly(c.end!);
      if (d.isBefore(start)) continue;
      if (end == null) {
        // 未结束：从 start 起一直算经期中
        return true;
      }
      if (!d.isAfter(end)) return true;
    }
    return false;
  }

  /// 某个区间内被标记为经期的日期（供日历着色）。
  Future<Set<DateTime>> periodDaysBetween(DateTime from, DateTime to) async {
    final rows = await (_db.select(_db.dailyRecords)
          ..where((t) =>
              t.isPeriodDay.equals(true) &
              t.date.isBiggerOrEqualValue(_dateOnly(from)) &
              t.date.isSmallerOrEqualValue(_dateOnly(to))))
        .get();
    return rows.map((r) => _dateOnly(r.date)).toSet();
  }

  // ---------------- 写 ----------------

  /// 记录「经期开始」。
  ///
  /// 返回 null 表示未写入（同一天重复点击、或该日已是经期日）。
  Future<DateTime?> startPeriod(DateTime date) async {
    final d = _dateOnly(date);

    return _db.transaction(() async {
      // 同一天重复点击保护
      final existing = await recordOf(d);
      if (existing?.isPeriodDay == true) return null;

      final open = await openCycle();
      if (open != null) {
        // 与当前周期同一天 → 视为重复点击
        if (_dateOnly(open.startDate) == d) return null;

        // 早于当前周期开始日 → 拒绝。
        // 否则会算出负的 cycleLength，把历史数据写坏。
        // （补记更早的周期属于「历史编辑」，留给后续任务，不在此处悄悄处理）
        if (d.isBefore(_dateOnly(open.startDate))) return null;

        // 关闭上一个周期：回填长度
        final length = d.difference(_dateOnly(open.startDate)).inDays;
        await (_db.update(_db.periodCycles)
              ..where((t) => t.id.equals(open.id)))
            .write(PeriodCyclesCompanion(
          cycleLength: Value(length),
          isClosed: const Value(true),
          updatedAt: Value(DateTime.now()),
        ));
      }

      final id = await _db.into(_db.periodCycles).insert(
            PeriodCyclesCompanion.insert(startDate: d),
          );

      await _upsertDaily(d, isPeriodDay: true, cycleId: id);
      return d;
    });
  }

  /// 记录「经期结束」。
  ///
  /// 只回填经期长度，不关闭周期（周期由下一次「经期开始」关闭）。
  /// 返回 false 表示当前没有进行中的周期、或日期早于开始日。
  Future<bool> endPeriod(DateTime date) async {
    final d = _dateOnly(date);

    return _db.transaction(() async {
      final open = await openCycle();
      if (open == null) return false;

      final start = _dateOnly(open.startDate);
      if (d.isBefore(start)) return false;

      final periodLength = d.difference(start).inDays + 1;

      await (_db.update(_db.periodCycles)
            ..where((t) => t.id.equals(open.id)))
          .write(PeriodCyclesCompanion(
        endDate: Value(d),
        periodLength: Value(periodLength),
        updatedAt: Value(DateTime.now()),
      ));

      // 把区间内每一天都标记为经期，日历/统计才连贯
      for (var i = 0; i < periodLength; i++) {
        await _upsertDaily(start.add(Duration(days: i)),
            isPeriodDay: true, cycleId: open.id);
      }
      return true;
    });
  }

  /// 补记 / 编辑一段历史经期（P4-1）。
  ///
  /// 与 [startPeriod] 的区别：那个是「今天来经期了」的实时记录，会拒绝
  /// 早于当前周期的日期；这里是**事后补录**，允许插到任意历史位置，
  /// 并重算相邻周期的 cycleLength（否则统计与预测会算错）。
  ///
  /// [end] 为空表示只记开始日（不知道哪天结束）。
  /// 返回结果里带人类可读的失败原因，UI 直接展示。
  Future<PeriodEditResult> upsertHistoricalPeriod({
    required DateTime start,
    DateTime? end,
  }) {
    return _applyEdit((existing) => const PeriodHistoryEditor().upsert(
          existing: existing,
          start: start,
          end: end,
          today: _now(),
        ));
  }

  /// 删除从 [start] 开始的那段经期（补记错了要能改）。
  Future<PeriodEditResult> deleteHistoricalPeriod(DateTime start) {
    return _applyEdit((existing) => const PeriodHistoryEditor()
        .remove(existing: existing, start: start));
  }

  /// 把某一段经期的结束日改到 [date]（点日历上的「经期到这天结束」）。
  ///
  /// 用命名参数：两个都是 DateTime，位置参数极易传反 —— 传反的后果不是报错，
  /// 而是悄悄新建一段"从 day 开始、到 day 结束"的单日经期。
  Future<PeriodEditResult> endPeriodAt({
    required DateTime cycleStart,
    required DateTime date,
  }) {
    return upsertHistoricalPeriod(start: cycleStart, end: date);
  }

  /// 撤销结束日：把该段改回「进行中」（endDate = null）。
  ///
  /// 对应月记 `PeriodRecordingService.removePeriodEnd` —— 用户点错
  /// 「经期到这天结束」时必须能退回去，否则只能删掉整段重录。
  Future<PeriodEditResult> clearPeriodEnd(DateTime start) {
    return upsertHistoricalPeriod(start: start);
  }

  /// 编辑结果落库：周期表重写 + daily_records 的经期日标记重建。
  ///
  /// 放在一个事务里：任何一步失败都不能留下「周期改了但日历没改」的脏状态。
  Future<PeriodEditResult> _applyEdit(
    PeriodEditResult Function(List<CycleInput>) build,
  ) async {
    return _db.transaction(() async {
      final rows = await _db.select(_db.periodCycles).get();
      final existing = rows.map(_toInput).toList(growable: false);
      final edit = build(existing);
      if (!edit.ok) return edit;

      final keepStarts = edit.cycles.map((c) => _dateOnly(c.start)).toSet();
      final idByStart = <DateTime, int>{};

      // 1) 写入/更新周期行
      for (final c in edit.cycles) {
        final idx = rows
            .indexWhere((r) => _dateOnly(r.startDate) == _dateOnly(c.start));
        final row = idx < 0 ? null : rows[idx];
        final closed = c.cycleLength != null;
        if (row == null) {
          final id = await _db.into(_db.periodCycles).insert(
                PeriodCyclesCompanion.insert(
                  startDate: _dateOnly(c.start),
                  endDate: Value(c.end),
                  cycleLength: Value(c.cycleLength),
                  periodLength: Value(c.periodLength),
                  isClosed: Value(closed),
                ),
              );
          idByStart[_dateOnly(c.start)] = id;
        } else {
          await (_db.update(_db.periodCycles)
                ..where((t) => t.id.equals(row.id)))
              .write(PeriodCyclesCompanion(
            endDate: Value(c.end),
            cycleLength: Value(c.cycleLength),
            periodLength: Value(c.periodLength),
            isClosed: Value(closed),
            updatedAt: Value(DateTime.now()),
          ));
          idByStart[_dateOnly(c.start)] = row.id;
        }
      }

      // 2) 删除已不在结果里的周期（仅删除场景会走到）
      for (final row in rows) {
        if (!keepStarts.contains(_dateOnly(row.startDate))) {
          await (_db.delete(_db.periodCycles)
                ..where((t) => t.id.equals(row.id)))
              .go();
        }
      }

      // 3) 重建 daily_records 的经期日标记
      final before = <DateTime>{};
      for (final r in rows) {
        before.addAll(_daysOf(_toInput(r)));
      }
      final editor = const PeriodHistoryEditor();
      final today = _dateOnly(_now());
      for (final d in edit.periodDays) {
        // 未结束周期按 5 天估算出来的「未来日期」不落库：
        // 日历只应该标到"今天"，把明天标成经期日是假数据。
        if (d.isAfter(today)) continue;
        final cycle = editor.cycleAt(edit.cycles, d);
        await _upsertDaily(
          d,
          isPeriodDay: true,
          cycleId: cycle == null ? null : idByStart[_dateOnly(cycle.start)],
        );
      }
      for (final d in before.difference(edit.periodDays)) {
        await _upsertDaily(d, isPeriodDay: false, clearCycleId: true);
      }

      return edit;
    });
  }

  static CycleInput _toInput(PeriodCycle r) => CycleInput(
        start: r.startDate,
        end: r.endDate,
        cycleLength: r.cycleLength,
        periodLength: r.periodLength,
      );

  static Set<DateTime> _daysOf(CycleInput c) {
    final s = _dateOnly(c.start);
    final e = c.end == null
        ? s.add(Duration(days: (c.resolvedPeriodLength ?? 5) - 1))
        : _dateOnly(c.end!);
    final out = <DateTime>{};
    var d = s;
    while (!d.isAfter(e)) {
      out.add(d);
      d = d.add(const Duration(days: 1));
    }
    return out;
  }

  /// 更新某天的经量与痛经等级（其他字段保持不动）。
  Future<void> updateDailyIntensity(
    DateTime date, {
    int? flowLevel,
    int? painLevel,
  }) async {
    final d = _dateOnly(date);
    final existing = await recordOf(d);
    if (existing == null) {
      await _db.into(_db.dailyRecords).insert(
            DailyRecordsCompanion.insert(
              date: d,
              flowLevel: Value(flowLevel),
              painLevel: Value(painLevel),
            ),
          );
      return;
    }

    await (_db.update(_db.dailyRecords)..where((t) => t.date.equals(d))).write(
      DailyRecordsCompanion(
        flowLevel:
            flowLevel == null ? const Value.absent() : Value(flowLevel),
        painLevel: painLevel == null ? const Value.absent() : Value(painLevel),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ---------------- 内部 ----------------

  Future<void> _upsertDaily(
    DateTime d, {
    bool? isPeriodDay,
    int? cycleId,
    bool clearCycleId = false,
  }) async {
    final existing = await recordOf(d);
    if (existing == null) {
      await _db.into(_db.dailyRecords).insert(
            DailyRecordsCompanion.insert(
              date: d,
              isPeriodDay: Value(isPeriodDay ?? false),
              cycleId: Value(cycleId),
            ),
          );
      return;
    }

    await (_db.update(_db.dailyRecords)..where((t) => t.date.equals(d))).write(
      DailyRecordsCompanion(
        isPeriodDay:
            isPeriodDay == null ? const Value.absent() : Value(isPeriodDay),
        cycleId: clearCycleId
            ? const Value(null)
            : (cycleId == null ? const Value.absent() : Value(cycleId)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
