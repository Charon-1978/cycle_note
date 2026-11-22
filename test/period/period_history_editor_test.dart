// test/period/period_history_editor_test.dart
//
// P4-1「补记历史经期」的纯逻辑验收。
//
// 重点锁住「周期长度」的重算规则，因为这是补记最容易写坏的地方：
//     周期长度 = 下一段开始日 − 本段开始日
// 于是「往前插一段」会改变它自己，「往中间插一段」会同时改变它和它前一段，
// 而最后一段永远没有 cycleLength（= 进行中）。
//
// 所有用例显式传 today，不依赖系统时钟。

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/features/period/services/period_history_editor.dart';
import 'package:cycle_note/features/period/services/period_prediction_service.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

/// 基准数据：间隔 28 天的两段 + 一段进行中（今天开始）
List<CycleInput> base() => [
      CycleInput(start: d(2026, 9, 26), end: d(2026, 9, 30)),
      CycleInput(start: d(2026, 10, 24), end: d(2026, 10, 28)),
      CycleInput(start: d(2026, 11, 21), end: null),
    ];

void main() {
  const editor = PeriodHistoryEditor();
  final today = d(2026, 11, 21);

  group('插入', () {
    test('补一段更早的经期 → 它自己拿到 28 天，其余不变', () {
      final r = editor.upsert(
        existing: base(),
        start: d(2026, 8, 29),
        end: d(2026, 9, 2),
        today: today,
      );

      expect(r.ok, isTrue);
      expect(r.cycles, hasLength(4));
      expect(r.cycles.first.start, d(2026, 8, 29));
      expect(r.cycles.first.cycleLength, 28); // 8/29 → 9/26
      expect(r.cycles[1].cycleLength, 28); // 9/26 → 10/24
      expect(r.cycles[2].cycleLength, 28); // 10/24 → 11/21
      expect(r.cycles.last.cycleLength, isNull); // 进行中
    });

    test('补一段中间经期 → 两侧 cycleLength 同时重算', () {
      // 该场景需要两侧都留出 ≥15 天间隔，所以用 44/37 天的长周期做底
      final wide = [
        CycleInput(start: d(2026, 9, 1), end: d(2026, 9, 5)),
        CycleInput(start: d(2026, 10, 15), end: d(2026, 10, 19)),
        CycleInput(start: d(2026, 11, 21), end: null),
      ];
      final r = editor.upsert(
        existing: wide,
        start: d(2026, 10, 31),
        end: d(2026, 11, 4),
        today: today,
      );

      expect(r.ok, isTrue);
      expect(r.cycles, hasLength(4));
      // 10/15 → 10/31 = 16 天；10/31 → 11/21 = 21 天
      expect(r.cycles[1].cycleLength, 16);
      expect(r.cycles[2].cycleLength, 21);
      expect(r.cycles.last.cycleLength, isNull);
    });

    test('只记开始日（end 为空）→ periodLength 为 null，区间按 5 天估算', () {
      final r = editor.upsert(
        existing: base(),
        start: d(2026, 10, 24),
        today: today,
      );

      expect(r.ok, isTrue);
      final c = r.cycles.firstWhere((x) => x.start == d(2026, 10, 24));
      expect(c.end, isNull);
      // 未结束：不臆造 periodLength
      expect(c.periodLength, isNull);
      expect(c.resolvedPeriodLength, isNull);
      expect(c.cycleLength, 28);
      // 但区间判定按「默认 5 天」估算，保证日历有东西可画
      expect(editor.cycleAt(r.cycles, d(2026, 10, 28))?.start, d(2026, 10, 24));
      expect(editor.cycleAt(r.cycles, d(2026, 10, 29)), isNull);
    });

    test('同一天再补 = 编辑结束日，不新增周期', () {
      final r = editor.upsert(
        existing: base(),
        start: d(2026, 10, 24),
        end: d(2026, 10, 30),
        today: today,
      );

      expect(r.ok, isTrue);
      expect(r.cycles, hasLength(3));
      final c = r.cycles.firstWhere((x) => x.start == d(2026, 10, 24));
      expect(c.end, d(2026, 10, 30));
      expect(c.periodLength, 7);
      expect(c.cycleLength, 28); // 下一段仍是 11/21
    });
  });

  group('校验', () {
    test('两次经期开始日间隔 <15 天 → 拒绝（美柚规则）', () {
      // 10/24 已有，补 11/7 只隔 14 天
      final r = editor.upsert(
        existing: base(),
        start: d(2026, 11, 7),
        end: d(2026, 11, 11),
        today: today,
      );

      expect(r.ok, isFalse);
      expect(r.error, contains('至少隔 15 天'));
    });

    test('间隔正好 15 天 → 允许', () {
      final r = editor.upsert(
        existing: base(),
        start: d(2026, 11, 8),
        end: d(2026, 11, 12),
        today: d(2026, 11, 21),
      );
      // 10/24 → 11/8 = 15 天；11/8 → 11/21 = 13 天 → 后者不足，仍应被拒
      expect(r.ok, isFalse);
      expect(r.error, contains('至少隔 15 天'));

      // 两端都 ≥15 才能过：换成更宽的底数据
      final wide = editor.upsert(
        existing: [
          CycleInput(start: d(2026, 10, 1), end: d(2026, 10, 5)),
          CycleInput(start: d(2026, 11, 21), end: null),
        ],
        start: d(2026, 10, 16),
        end: d(2026, 10, 20),
        today: today,
      );
      expect(wide.ok, isTrue);
      expect(wide.cycles[0].cycleLength, 15);
    });

    test('间隔够但区间重叠 → 拒绝（防御外部导入的超长经期）', () {
      final odd = [
        CycleInput(start: d(2026, 10, 1), end: d(2026, 10, 25)),
        CycleInput(start: d(2026, 11, 21), end: null),
      ];
      final r = editor.upsert(
        existing: odd,
        start: d(2026, 10, 20),
        end: d(2026, 10, 22),
        today: today,
      );
      expect(r.ok, isFalse);
      expect(r.error, contains('重叠'));
    });

    test('结束日早于开始日 → 拒绝', () {
      final r = editor.upsert(
        existing: base(),
        start: d(2026, 9, 10),
        end: d(2026, 9, 8),
        today: today,
      );
      expect(r.ok, isFalse);
      expect(r.error, contains('不能早于'));
    });

    test('补记未来日期 → 拒绝', () {
      final future = editor.upsert(
        existing: base(),
        start: d(2026, 11, 25),
        today: today,
      );
      expect(future.ok, isFalse);
      expect(future.error, contains('未来'));
    });

    test('经期长度越界（<1 / >30）→ 拒绝；1 天与 20 天的异常经期允许', () {
      // 结束日早于开始日 → 拒绝（长度为负）
      final inverted = editor.upsert(
        existing: base(),
        start: d(2026, 9, 10),
        end: d(2026, 9, 8),
        today: today,
      );
      expect(inverted.ok, isFalse);

      final tooLong = editor.upsert(
        existing: base(),
        start: d(2026, 9, 10),
        end: d(2026, 10, 11),
        today: today,
      );
      expect(tooLong.ok, isFalse);
      expect(tooLong.error, contains('最长'));

      // 异常经期：20 天必须允许（用户反馈"淋漓两三周"要能记）
      final longPeriod = editor.upsert(
        existing: base(),
        start: d(2026, 9, 1),
        end: d(2026, 9, 20),
        today: today,
      );
      expect(longPeriod.ok, isTrue);
      expect(
        longPeriod.cycles.firstWhere((c) => c.start == d(2026, 9, 1)).periodLength,
        20,
      );

      // 1 天（点滴/只来一天）也要允许
      final oneDay = editor.upsert(
        existing: base(),
        start: d(2026, 8, 5),
        end: d(2026, 8, 5),
        today: today,
      );
      expect(oneDay.ok, isTrue);
    });
  });

  group('删除', () {
    test('删中间一段 → 前一段 cycleLength 重算到下一段', () {
      final r = editor.remove(existing: base(), start: d(2026, 10, 24));

      expect(r.ok, isTrue);
      expect(r.cycles, hasLength(2));
      // 9/26 → 11/21 = 56 天
      expect(r.cycles.first.cycleLength, 56);
      expect(r.cycles.last.cycleLength, isNull);
    });

    test('删不存在的日期 → 明确报错', () {
      final r = editor.remove(existing: base(), start: d(2026, 1, 1));
      expect(r.ok, isFalse);
      expect(r.error, contains('没有找到'));
    });
  });

  group('辅助判定', () {
    test('cycleAt 命中区间内 / 落在区间外', () {
      expect(editor.cycleAt(base(), d(2026, 10, 26))?.start, d(2026, 10, 24));
      expect(editor.cycleAt(base(), d(2026, 10, 30)), isNull);
    });

    test('periodDays 覆盖每一段的完整区间', () {
      final r = editor.upsert(
        existing: base(),
        start: d(2026, 9, 26),
        end: d(2026, 9, 30),
        today: today,
      );
      // 9/26-9/30 (5) + 10/24-10/28 (5) + 11/21 起估 5 天 (5) = 15
      expect(r.periodDays, hasLength(15));
      expect(r.periodDays.contains(d(2026, 9, 28)), isTrue);
      expect(r.periodDays.contains(d(2026, 10, 1)), isFalse);
    });
  });

  group('maxBackfillDays（补记只能补到今天的唯一口径）', () {
    final today = d(2026, 11, 22);

    test('起点就是今天 → 只能补 1 天', () {
      expect(maxBackfillDays(start: today, today: today), 1);
    });

    test('起点是今天往前 4 天 → 5 天', () {
      expect(
        maxBackfillDays(start: d(2026, 11, 18), today: today),
        5,
      );
    });

    test('起点是今天 20 天前 → 21 天（异常经期也能补）', () {
      expect(maxBackfillDays(start: d(2026, 11, 2), today: today), 21);
    });

    test('起点 40 天前 → 封顶到 30 天（一个月内的物理上限）', () {
      expect(
        maxBackfillDays(start: d(2026, 10, 13), today: today),
        PeriodHistoryEditor.maxPeriodLength,
      );
    });

    test('起点在未来 → 0（这一天不该被补记）', () {
      expect(maxBackfillDays(start: d(2026, 11, 23), today: today), 0);
      expect(maxBackfillDays(start: d(2026, 12, 1), today: today), 0);
    });

    test('跨月：10/30 到今天 11/2 → 4 天', () {
      expect(
        maxBackfillDays(start: d(2026, 10, 30), today: d(2026, 11, 2)),
        4,
      );
    });

    test('跨年：12/30 到次年 1/2 → 4 天', () {
      expect(
        maxBackfillDays(start: d(2025, 12, 30), today: d(2026, 1, 2)),
        4,
      );
    });

    test('时分秒不影响判断（只按日期算）', () {
      final start = DateTime(2026, 11, 20, 23, 59);
      final lateToday = DateTime(2026, 11, 22, 0, 1);
      expect(maxBackfillDays(start: start, today: lateToday), 3);
    });
  });
}

