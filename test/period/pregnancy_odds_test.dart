// test/period/pregnancy_odds_test.dart
//
// 这些断言的期望值全部可以用原 JS（assets/pregnancyOdds.js）手算出来，
// 用于确认 Dart 移植没有走样。

import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/features/period/services/pregnancy_odds_service.dart';

void main() {
  const svc = PregnancyOddsService();

  group('自然概率（无同房记录）', () {
    test('排卵日 = 90%', () {
      expect(
        svc.calculate(phase: OddsPhase.ovulation),
        closeTo(90, 0.001),
      );
    });

    test('月经期 = 10%，安全期 = 15%', () {
      expect(svc.calculate(phase: OddsPhase.menstrual), closeTo(10, 0.001));
      expect(svc.calculate(phase: OddsPhase.safe), closeTo(15, 0.001));
    });

    test('易孕期第 1 天 = 35%，第 6 天 = 90%（峰值）', () {
      expect(
        svc.calculate(phase: OddsPhase.fertile, easyDayIndex: 1),
        closeTo(35, 0.001),
      );
      expect(
        svc.calculate(phase: OddsPhase.fertile, easyDayIndex: 6),
        closeTo(90, 0.001),
      );
    });

    test('易孕期索引越界（11 天）返回 0', () {
      expect(
        svc.calculate(phase: OddsPhase.fertile, easyDayIndex: 11),
        0,
      );
    });
  });

  group('单次同房的避孕修正', () {
    test('排卵日 + 安全套 = 1%（0.9 × 0.01）', () {
      expect(
        svc.calculate(
          phase: OddsPhase.ovulation,
          records: const [IntercourseRecord(usedCondom: true)],
        ),
        closeTo(1, 0.001),
      );
    });

    test('排卵日 + 避孕药 = 2%（0.9 × 0.02 四舍五入到 2 位）', () {
      expect(
        svc.calculate(
          phase: OddsPhase.ovulation,
          records: const [IntercourseRecord(takenBirthControlPill: true)],
        ),
        closeTo(2, 0.001),
      );
    });

    test('排卵日 + 体外 = 5%（0.9 × 0.05 = 0.045 → 0.05）', () {
      expect(
        svc.calculate(
          phase: OddsPhase.ovulation,
          records: const [IntercourseRecord(withdrawal: true)],
        ),
        closeTo(5, 0.001),
      );
    });

    test('排卵日 + 无措施 = 90%', () {
      expect(
        svc.calculate(
          phase: OddsPhase.ovulation,
          records: const [IntercourseRecord(hadUnprotected: true)],
        ),
        closeTo(90, 0.001),
      );
    });
  });

  group('多次同房：1 − Π(1 − p)', () {
    test('排卵日两次无措施 = 99%（1 − 0.1 × 0.1）', () {
      expect(
        svc.calculate(
          phase: OddsPhase.ovulation,
          records: const [
            IntercourseRecord(hadUnprotected: true),
            IntercourseRecord(hadUnprotected: true),
          ],
        ),
        closeTo(99, 0.001),
      );
    });

    test('当天服用了避孕药 → 除安全套外全部按 0.02', () {
      // 第一条无措施(1.0) 第二条吃药：usePill=true
      // → 两条都走 0.02 分支（第二条命中 takenBirthControlPill）
      // p = 0.9×0.02 = 0.018，1 − (1−0.018)² = 0.0357 → 3.57 → round2=0.04 → 4
      final v = svc.calculate(
        phase: OddsPhase.ovulation,
        records: const [
          IntercourseRecord(hadUnprotected: true),
          IntercourseRecord(takenBirthControlPill: true),
        ],
      );
      expect(v, closeTo(4, 0.001));
    });

    test('两次都用安全套 → 2%（1 − 0.991² = 0.0179 → 0.02）', () {
      final v = svc.calculate(
        phase: OddsPhase.ovulation,
        records: const [
          IntercourseRecord(usedCondom: true),
          IntercourseRecord(usedCondom: true),
        ],
      );
      expect(v, closeTo(2, 0.001));
    });
  });

  group('边界收敛', () {
    test('结果不超过 99', () {
      final v = svc.calculate(
        phase: OddsPhase.ovulation,
        records: List.generate(
          5,
          (_) => const IntercourseRecord(hadUnprotected: true),
        ),
      );
      expect(v, lessThanOrEqualTo(99));
    });

    test('结果不为 0', () {
      expect(
        svc.calculate(
          phase: OddsPhase.menstrual,
          records: const [IntercourseRecord(usedCondom: true)],
        ),
        greaterThanOrEqualTo(1),
      );
    });
  });
}
