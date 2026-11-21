// test/period/period_prediction_test.dart
//
// 覆盖：
//   1) 规律 28 天 → 周期 28、排卵 = 下次经期 − 14、易孕期 = 排卵 −5 … +1
//   2) 单个异常周期被稳健剔除（中位数 + 容差）
//   3) 预测日已过 → 顺延到未来
//   4) phaseOf 的优先级：已记录经期 > 预测经期 > 排卵 > 易孕 > 普通
//   5) 数据不足时返回 null，不瞎猜

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/features/period/services/period_prediction_service.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  const svc = PeriodPredictionService();

  /// 6 个规律 28 天周期
  List<CycleInput> regular28() => [
        for (var i = 0; i < 6; i++)
          CycleInput(
            start: d(2026, 1, 1).add(Duration(days: 28 * i)),
            cycleLength: 28,
            periodLength: 5,
          ),
      ];

  group('基础预测', () {
    test('规律 28 天：周期/经期/排卵/易孕期全部正确', () {
      final p = svc.predict(regular28(), today: d(2026, 6, 10))!;

      expect(p.cycleLength, 28);
      expect(p.periodLength, 5);
      // 最后一次是 05-21，+28 = 06-18
      expect(p.periodStart, d(2026, 6, 18));
      expect(p.periodEnd, d(2026, 6, 22)); // 5 天
      expect(p.ovulation, d(2026, 6, 4)); // 06-18 − 14
      expect(p.fertileStart, d(2026, 5, 30)); // 排卵 − 5
      expect(p.fertileEnd, d(2026, 6, 5)); // 排卵 + 1
      expect(p.basedOnCycles, 6);
      expect(p.confidence, 90); // 6 样本、零离散
    });

    test('预测日已过 → 顺延到未来', () {
      final p = svc.predict(regular28(), today: d(2026, 7, 1))!;
      expect(p.periodStart, d(2026, 7, 16)); // 06-18 + 28
      expect(p.periodStart.isAfter(d(2026, 7, 1)), isTrue);
    });

    test('单个异常周期被剔除（45 天不污染结果）', () {
      final cycles = <CycleInput>[
        CycleInput(start: d(2026, 1, 1), cycleLength: 28, periodLength: 5),
        CycleInput(start: d(2026, 1, 29), cycleLength: 45, periodLength: 5),
        CycleInput(start: d(2026, 3, 15), cycleLength: 28, periodLength: 5),
        CycleInput(start: d(2026, 4, 12), cycleLength: 28, periodLength: 5),
        CycleInput(start: d(2026, 5, 10), cycleLength: 28, periodLength: 5),
        CycleInput(start: d(2026, 6, 7), cycleLength: 28, periodLength: 5),
      ];
      final p = svc.predict(cycles, today: d(2026, 6, 20))!;

      expect(p.cycleLength, 28); // 45 被剔除
      expect(p.basedOnCycles, 5);
    });

    test('未记录经期天数时用默认 5 天', () {
      final p = svc.predict([
        CycleInput(start: d(2026, 1, 1), cycleLength: 28),
        CycleInput(start: d(2026, 1, 29), cycleLength: 28),
      ], today: d(2026, 2, 1))!;
      expect(p.periodLength, 5);
    });

    test('无数据 / 无有效长度 → null（不瞎猜）', () {
      expect(svc.predict(const [], today: d(2026, 6, 1)), isNull);
      expect(
        svc.predict([CycleInput(start: d(2026, 1, 1))], today: d(2026, 2, 1)),
        isNull,
      );
    });

    test('样本越少置信度越低', () {
      final one = svc.predict([
        CycleInput(start: d(2026, 1, 1), cycleLength: 28, periodLength: 5),
      ], today: d(2026, 1, 10))!;
      final six = svc.predict(regular28(), today: d(2026, 6, 10))!;
      expect(one.confidence, lessThan(six.confidence));
      expect(one.confidence, inInclusiveRange(5, 95));
    });
  });

  group('phaseOf 优先级', () {
    test('已记录经期 > 预测；排卵日/易孕期/普通日正确', () {
      final cycles = regular28();
      final p = svc.predict(cycles, today: d(2026, 6, 10))!;

      // 已记录周期首日 05-21 落在经期
      expect(
        svc.phaseOf(d(2026, 5, 21), prediction: p, recordedCycles: cycles),
        CyclePhase.menstrual,
      );
      // 排卵日
      expect(
        svc.phaseOf(d(2026, 6, 4), prediction: p, recordedCycles: cycles),
        CyclePhase.ovulation,
      );
      // 易孕期首日 / 末日
      expect(
        svc.phaseOf(d(2026, 5, 30), prediction: p, recordedCycles: cycles),
        CyclePhase.fertile,
      );
      expect(
        svc.phaseOf(d(2026, 6, 5), prediction: p, recordedCycles: cycles),
        CyclePhase.fertile,
      );
      // 易孕期结束后一天
      expect(
        svc.phaseOf(d(2026, 6, 6), prediction: p, recordedCycles: cycles),
        CyclePhase.normal,
      );
    });

    test('无预测时一律普通日', () {
      expect(
        svc.phaseOf(d(2026, 6, 4), prediction: null),
        CyclePhase.normal,
      );
    });
  });

  test('daysUntilNextPeriod 计算正确（含负数）', () {
    final p = svc.predict(regular28(), today: d(2026, 6, 10))!;
    expect(svc.daysUntilNextPeriod(p, today: d(2026, 6, 10)), 8); // 06-18 − 06-10
    expect(svc.daysUntilNextPeriod(p, today: d(2026, 6, 20)), -2);
  });
}
