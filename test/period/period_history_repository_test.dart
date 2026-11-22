// test/period/period_history_repository_test.dart
//
// P4-1 的落库验收：补记/删除不仅改周期表，还要把 daily_records 的
// 「经期日」标记一起重建，否则日历着色会与周期表打架。
//
// 全部用内存库跑真实事务。

import 'package:drift/drift.dart' show OrderingTerm;
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

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // 「今天」锁死在 11/21：下面所有断言（56 天、28/28）都以它为基准。
    // 注入时钟而不是用真实 DateTime.now()，否则每过一天就红一次。
    repo = PeriodRepository(db, now: () => d(2026, 11, 21));

    // 基线：两段历史 + 一个进行中（今天）
    await repo.upsertHistoricalPeriod(
      start: d(2026, 9, 26),
      end: d(2026, 9, 30),
    );
    await repo.upsertHistoricalPeriod(
      start: d(2026, 10, 24),
      end: d(2026, 10, 28),
    );
    await repo.startPeriod(d(2026, 11, 21));
  });

  tearDown(() async {
    await db.close();
  });

  group('补记历史经期', () {
    test('插入更早一段：写库成功且相邻 cycleLength 重算', () async {
      final r = await repo.upsertHistoricalPeriod(
        start: d(2026, 8, 29),
        end: d(2026, 9, 2),
      );

      expect(r.ok, isTrue);

      final rows = await (db.select(db.periodCycles)
            ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
          .get();
      // 基线 3 段（9/26、10/24、今天）+ 新补的一段 = 4
      expect(rows.length, 4);
      expect(rows[0].startDate, d(2026, 8, 29));
      expect(rows[0].cycleLength, 28); // 8/29 → 9/26
      expect(rows[0].isClosed, isTrue);
      expect(rows[1].cycleLength, 28);
      // 最后一段（今天）是进行中
      expect(rows.last.cycleLength, isNull);
      expect(rows.last.isClosed, isFalse);
    });

    test('补记后 daily_records 的经期日与区间一致', () async {
      await repo.upsertHistoricalPeriod(
        start: d(2026, 8, 29),
        end: d(2026, 9, 2),
      );

      expect((await repo.recordOf(d(2026, 8, 29)))?.isPeriodDay, isTrue);
      expect((await repo.recordOf(d(2026, 9, 2)))?.isPeriodDay, isTrue);
      expect((await repo.recordOf(d(2026, 9, 3)))?.isPeriodDay, isNot(true));

      // 覆盖 8/29-9/2 (5) + 9/26-9/30 (5) + 10/24-10/28 (5) + 今天 (1)
      // 未结束周期只标到今天，未来日期不落库
      final marked = await repo.periodDaysBetween(
        d(2026, 8, 1),
        d(2026, 12, 31),
      );
      expect(marked.length, 16);
    });

    test('改结束日：periodLength 更新，daily 标记缩短', () async {
      // 原 9/26-9/30 是 5 天，改成 9/28 结束 = 3 天
      final r = await repo.upsertHistoricalPeriod(
        start: d(2026, 9, 26),
        end: d(2026, 9, 28),
      );
      expect(r.ok, isTrue);

      final cycle = (await db.select(db.periodCycles).get())
          .firstWhere((c) => c.startDate == d(2026, 9, 26));
      expect(cycle.periodLength, 3);

      expect((await repo.recordOf(d(2026, 9, 28)))?.isPeriodDay, isTrue);
      // 9/29-9/30 应被清掉
      expect((await repo.recordOf(d(2026, 9, 29)))?.isPeriodDay, isFalse);
    });

    test('重叠补记被拒绝，且数据库不被改动', () async {
      final before = await (db.select(db.periodCycles)
            ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
          .get();

      final r = await repo.upsertHistoricalPeriod(
        start: d(2026, 10, 26),
        end: d(2026, 10, 30),
      );
      expect(r.ok, isFalse);

      final after = await (db.select(db.periodCycles)
            ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
          .get();
      expect(after.length, before.length);
      expect(after.map((e) => e.startDate).toList(),
          before.map((e) => e.startDate).toList());
    });
  });

  group('删除历史经期', () {
    test('删除后行消失、cycleLength 重算、daily 标记清除', () async {
      final r = await repo.deleteHistoricalPeriod(d(2026, 10, 24));
      expect(r.ok, isTrue);

      final rows = await (db.select(db.periodCycles)
            ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
          .get();
      expect(rows.length, 2); // 9/26 + 今天
      expect(rows.first.startDate, d(2026, 9, 26));

      // 9/26 → 今天（11/21）= 56 天
      expect(rows.first.cycleLength, 56);

      expect((await repo.recordOf(d(2026, 10, 26)))?.isPeriodDay, isFalse);
    });
  });

  group('端到端：补记后预测可用', () {
    test('三段规律历史 → 预测出下次经期与排卵日', () async {
      final cycles = await repo.loadCycles();
      // 9/26、10/24、今天（11/21）→ 两个 28 天周期
      expect(cycles.length, 3);

      final lengths = cycles
          .map((c) => c.cycleLength)
          .whereType<int>()
          .toList();
      expect(lengths, everyElement(28));
    });
  });
}
