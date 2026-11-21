// test/database/app_database_test.dart
//
// 验证 Schema 本身可用：
//   1) 内存库能创建全部 9 张表（减脂 6 + 经期 3）
//   2) 经期表可写入/读回（含 boolean 列）
//   3) 每日记录以 date 为主键（同一天重复插入会冲突 → 用 onConflictUpdate 覆盖）
//   4) v3 新增的 CustomFoods 可用，且 code 唯一约束真的存在

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/data/local/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    // beforeOpen 会记录 schema 版本，需要 mock
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('全部 9 张表可访问', () async {
    // 触发建表
    expect(await db.select(db.periodCycles).get(), isEmpty);
    expect(await db.select(db.dailyRecords).get(), isEmpty);
    expect(await db.select(db.predictionCaches).get(), isEmpty);
    expect(await db.select(db.weightLogs).get(), isEmpty);
    expect(await db.select(db.exerciseLogs).get(), isEmpty);
    expect(await db.select(db.mealLogs).get(), isEmpty);
    expect(await db.select(db.bodyProfiles).get(), isEmpty);
    expect(await db.select(db.calorieBudgets).get(), isEmpty);
    expect(await db.select(db.customFoods).get(), isEmpty);
  });

  test('CustomFoods 的 code 唯一约束真实存在', () async {
    await db.into(db.customFoods).insert(
          CustomFoodsCompanion.insert(
            code: 'custom_1',
            name: '测试食物',
            kcalPer100g: 100,
          ),
        );
    // 相同 code 再插必须抛异常（否则 saveCustomFood 的"先查后写"就没有意义）
    await expectLater(
      db.into(db.customFoods).insert(
            CustomFoodsCompanion.insert(
              code: 'custom_1',
              name: '重复食物',
              kcalPer100g: 200,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test('迁移版本号必须与文档一致（只增不减）', () {
    // 改这里之前先想清楚：这个数字一旦减小，老用户会走不到新迁移分支
    expect(AppDatabase.kSchemaVersion, 3);
  });

  test('周期可写入并读回', () async {
    await db.into(db.periodCycles).insert(
          PeriodCyclesCompanion.insert(
            startDate: DateTime(2026, 5, 21),
            endDate: Value(DateTime(2026, 5, 25)),
            cycleLength: const Value(28),
            periodLength: const Value(5),
            isClosed: const Value(true),
          ),
        );

    final rows = await db.select(db.periodCycles).get();
    expect(rows.length, 1);
    expect(rows.single.cycleLength, 28);
    expect(rows.single.isClosed, isTrue);
  });

  test('每日记录以 date 为主键，重复插入需覆盖', () async {
    final date = DateTime(2026, 6, 1);

    await db.into(db.dailyRecords).insert(
          DailyRecordsCompanion.insert(
            date: date,
            flowLevel: const Value(2),
            sexualActivity: const Value(true),
          ),
        );

    // 同一天再插一条应抛异常（主键冲突）
    await expectLater(
      db.into(db.dailyRecords).insert(
            DailyRecordsCompanion.insert(
              date: date,
              flowLevel: const Value(3),
            ),
          ),
      throwsA(isA<Exception>()),
    );

    // 改用 insertOnConflictUpdate 覆盖
    await db.into(db.dailyRecords).insertOnConflictUpdate(
          DailyRecordsCompanion.insert(
            date: date,
            flowLevel: const Value(3),
          ),
        );

    final rows = await db.select(db.dailyRecords).get();
    expect(rows.length, 1);
    expect(rows.single.flowLevel, 3);
  });

  test('预测缓存可写入并读回', () async {
    await db.into(db.predictionCaches).insert(
          PredictionCachesCompanion.insert(
            predictedPeriodStart: DateTime(2026, 6, 18),
            predictedPeriodEnd: DateTime(2026, 6, 22),
            predictedOvulationDate: Value(DateTime(2026, 6, 4)),
            fertileStart: Value(DateTime(2026, 5, 30)),
            fertileEnd: Value(DateTime(2026, 6, 5)),
            confidenceLevel: 90,
            basedOnCycles: 6,
          ),
        );

    final rows = await db.select(db.predictionCaches).get();
    expect(rows.single.confidenceLevel, 90);
    // 用 isA 而非 isNotNull：drift 与 flutter_test 都导出了 isNotNull，会歧义
    expect(rows.single.predictedOvulationDate, isA<DateTime>());
    expect(rows.single.fertileStart, isA<DateTime>());
  });
}
