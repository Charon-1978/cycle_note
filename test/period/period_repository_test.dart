// test/period/period_repository_test.dart
//
// 覆盖 P1-7 的领域规则：
//   1) 「经期开始」= 关闭上一个周期（回填 cycleLength）+ 开启新周期 + 标记当日
//   2) 「经期结束」= 只回填 endDate/periodLength（不关闭周期）
//   3) 同一天重复点击不产生重复周期
//   4) 区间内每一天都被标记为经期
//   5) isInPeriod 的边界正确

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/features/period/data/period_repository.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late PeriodRepository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = PeriodRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('经期开始', () {
    test('创建周期并标记当日为经期日', () async {
      final r = await repo.startPeriod(d(2026, 1, 1));

      expect(r, d(2026, 1, 1));

      final cycles = await db.select(db.periodCycles).get();
      expect(cycles.length, 1);
      expect(cycles.single.startDate, d(2026, 1, 1));
      expect(cycles.single.isClosed, isFalse);
      expect(cycles.single.cycleLength, isNull);

      final daily = await repo.recordOf(d(2026, 1, 1));
      expect(daily?.isPeriodDay, isTrue);
      expect(daily?.cycleId, cycles.single.id);
    });

    test('同一天重复点击不会产生第二个周期', () async {
      await repo.startPeriod(d(2026, 1, 1));
      final again = await repo.startPeriod(d(2026, 1, 1));

      expect(again, isNull);
      expect((await db.select(db.periodCycles).get()).length, 1);
    });

    test('第二次开始会关闭上一个周期并回填 cycleLength', () async {
      await repo.startPeriod(d(2026, 1, 1));
      await repo.startPeriod(d(2026, 1, 29)); // 相隔 28 天

      final cycles = await db.select(db.periodCycles).get()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));

      expect(cycles.length, 2);
      expect(cycles[0].isClosed, isTrue);
      expect(cycles[0].cycleLength, 28);
      expect(cycles[1].isClosed, isFalse);
      expect(cycles[1].cycleLength, isNull);
    });
  });

  group('经期结束', () {
    test('回填 endDate 与 periodLength（间隔天数 + 1）', () async {
      await repo.startPeriod(d(2026, 1, 1));
      final ok = await repo.endPeriod(d(2026, 1, 5));

      expect(ok, isTrue);

      final cycle = (await db.select(db.periodCycles).get()).single;
      expect(cycle.endDate, d(2026, 1, 5));
      expect(cycle.periodLength, 5); // 1..5 共 5 天
      // 经期结束不等于周期结束
      expect(cycle.isClosed, isFalse);
    });

    test('区间内每一天都被标记为经期日', () async {
      await repo.startPeriod(d(2026, 1, 1));
      await repo.endPeriod(d(2026, 1, 4));

      final rows = await db.select(db.dailyRecords).get();
      expect(rows.length, 4);
      expect(rows.every((r) => r.isPeriodDay), isTrue);
    });

    test('没有进行中的周期时返回 false', () async {
      expect(await repo.endPeriod(d(2026, 1, 5)), isFalse);
    });

    test('结束日早于开始日时拒绝', () async {
      await repo.startPeriod(d(2026, 1, 10));
      expect(await repo.endPeriod(d(2026, 1, 5)), isFalse);
    });
  });

  group('isInPeriod 边界', () {
    test('开始日在内、结束日在内、次日在外', () async {
      await repo.startPeriod(d(2026, 1, 1));
      await repo.endPeriod(d(2026, 1, 5));

      expect(await repo.isInPeriod(d(2026, 1, 1)), isTrue);
      expect(await repo.isInPeriod(d(2026, 1, 5)), isTrue);
      expect(await repo.isInPeriod(d(2026, 1, 6)), isFalse);
      expect(await repo.isInPeriod(d(2025, 12, 31)), isFalse);
    });

    test('未结束的经期从开始日一直算经期中', () async {
      await repo.startPeriod(d(2026, 1, 1));
      expect(await repo.isInPeriod(d(2026, 1, 20)), isTrue);
    });
  });

  group('其他', () {
    test('updateDailyIntensity 可写入并更新经量', () async {
      await repo.startPeriod(d(2026, 1, 1));
      await repo.updateDailyIntensity(d(2026, 1, 1), flowLevel: 2);

      var rec = await repo.recordOf(d(2026, 1, 1));
      expect(rec?.flowLevel, 2);
      expect(rec?.isPeriodDay, isTrue); // 其他字段不受影响

      await repo.updateDailyIntensity(d(2026, 1, 1), flowLevel: 3);
      rec = await repo.recordOf(d(2026, 1, 1));
      expect(rec?.flowLevel, 3);
    });

    test('loadCycles 按时间升序且映射正确', () async {
      // 按时间顺序记录：1月 → 2月 → 3月
      await repo.startPeriod(d(2026, 1, 1));
      await repo.startPeriod(d(2026, 2, 1));
      await repo.startPeriod(d(2026, 3, 1));

      final cycles = await repo.loadCycles();
      expect(cycles.map((c) => c.start).toList(), [
        d(2026, 1, 1),
        d(2026, 2, 1),
        d(2026, 3, 1),
      ]);
      // 前两个应已被关闭并回填长度
      expect(cycles[0].cycleLength, 31); // 01-01 → 02-01
      expect(cycles[1].cycleLength, 28); // 02-01 → 03-01
      expect(cycles[2].cycleLength, isNull);
    });

    test('补记早于当前周期的日期会被拒绝（防止负 cycleLength）', () async {
      await repo.startPeriod(d(2026, 3, 1));

      final rejected = await repo.startPeriod(d(2026, 1, 1));

      expect(rejected, isNull);
      final cycles = await db.select(db.periodCycles).get();
      expect(cycles.length, 1);
      expect(cycles.single.cycleLength, isNull); // 没有被写成负数
    });

    test('periodDaysBetween 返回区间内经期日集合', () async {
      await repo.startPeriod(d(2026, 1, 1));
      await repo.endPeriod(d(2026, 1, 3));

      final days = await repo.periodDaysBetween(d(2026, 1, 1), d(2026, 1, 31));
      expect(days.length, 3);
      expect(days.contains(d(2026, 1, 2)), isTrue);
    });
  });
}
