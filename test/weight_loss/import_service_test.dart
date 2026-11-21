// test/weight_loss/import_service_test.dart
//
// P5-1「导入 / 恢复」验收，重点是 Gate 2 那条硬要求：
//   **导出 → 清空 → 导入 → 往返一致（数据无损）**
//
// 另锁三件事：
//   1) CSV 解析符合 RFC 4180（BOM / 引号 / 换行 / 空行）
//   2) 类型识别按表头签名，不认识的表头明确报错而不是静默忽略
//   3) 幂等：同一批文件导两次，第二次全部计入 skipped，不产生重复

import 'dart:io';

import 'package:drift/drift.dart' show Value, OrderingTerm;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/features/weight_loss/services/export_service.dart';
import 'package:cycle_note/features/weight_loss/services/import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Directory tmp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tmp = await Directory.systemTemp.createTemp('yueji_import_test');
  });

  tearDown(() async {
    await db.close();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('CSV 解析', () {
    test('去 BOM、支持引号字段与 CRLF', () {
      const raw = '日期,经期日,经量,痛经\r\n'
          '2026-09-26,是,2,1\r\n'
          '2026-09-27,是,,"偏 重"\r\n';
      final table = ImportService.parseCsv(raw);
      expect(table.header, ['日期', '经期日', '经量', '痛经']);
      expect(table.rows, hasLength(2));
      expect(table.cell(table.rows[0], '经量'), '2');
      expect(table.cell(table.rows[1], '经量'), isNull); // 空字段 → null
      expect(table.cell(table.rows[1], '痛经'), '偏 重');
    });

    test('引号内的逗号与转义引号不被当分隔符', () {
      final table = ImportService.parseCsv(
        'a,b,c\n"x,y","he said ""hi""",z\n',
      );
      expect(table.rows.single, ['x,y', 'he said "hi"', 'z']);
    });

    test('末尾空行不会造出空记录', () {
      final table = ImportService.parseCsv('a,b\n1,2\n\n\n');
      expect(table.rows, hasLength(1));
    });
  });

  group('类型识别', () {
    test('五类表头各自识别正确', () {
      CsvTable t(List<String> h) => CsvTable(header: h, rows: const []);
      expect(ImportService.detect(t(['开始日期', '结束日期'])),
          ImportKind.periodCycle);
      expect(ImportService.detect(t(['日期', '经期日', '经量', '痛经'])),
          ImportKind.periodDay);
      expect(ImportService.detect(t(['记录时间', '体重(kg)'])),
          ImportKind.weight);
      expect(ImportService.detect(t(['记录时间', '运动名称'])),
          ImportKind.exercise);
      expect(ImportService.detect(t(['记录时间', '餐次', '食物'])),
          ImportKind.meal);
      expect(ImportService.detect(t(['随便', '什么'])), ImportKind.unknown);
    });
  });

  group('往返一致（Gate 2）', () {
    test('五类数据导出 → 清空 → 导入后逐字段一致', () async {
      // ---- 造数据 ----
      await db.into(db.weightLogs).insert(WeightLogsCompanion.insert(
            recordedAt: DateTime(2026, 9, 2, 8, 30),
            weightKg: 55.4,
            bodyFatPercent: const Value(27.5),
            note: const Value('晨起'),
          ));
      await db.into(db.exerciseLogs).insert(ExerciseLogsCompanion.insert(
            recordedAt: DateTime(2026, 9, 2, 19, 0),
            exerciseCode: 'walking',
            exerciseName: '快走',
            met: 4.3,
            minutes: 30,
            weightKgAtTime: 55.4,
            kcal: 120.5,
          ));
      await db.into(db.mealLogs).insert(MealLogsCompanion.insert(
            recordedAt: DateTime(2026, 9, 2, 12, 20),
            mealType: 'lunch',
            foodCode: 'chicken_breast',
            foodName: '鸡胸肉',
            grams: 150,
            kcal: 199.5,
            proteinG: const Value(36.9),
            fatG: const Value(3.75),
            carbG: const Value(0.9),
          ));
      await db.into(db.periodCycles).insert(PeriodCyclesCompanion.insert(
            startDate: DateTime(2026, 8, 1),
            endDate: Value(DateTime(2026, 8, 5)),
            cycleLength: const Value(28),
            periodLength: const Value(5),
            isClosed: const Value(true),
          ));
      await db.into(db.dailyRecords).insert(DailyRecordsCompanion.insert(
            date: DateTime(2026, 8, 2),
            isPeriodDay: const Value(true),
            flowLevel: const Value(2),
            painLevel: const Value(1),
          ));

      // ---- 导出 ----
      final files = await const ExportService().exportAll(db, tmp);
      expect(files, hasLength(5));

      // ---- 清空 ----
      await db.delete(db.weightLogs).go();
      await db.delete(db.exerciseLogs).go();
      await db.delete(db.mealLogs).go();
      await db.delete(db.periodCycles).go();
      await db.delete(db.dailyRecords).go();
      expect(await db.select(db.weightLogs).get(), isEmpty);

      // ---- 导入 ----
      final report = await const ImportService().importFiles(db, files);
      expect(report.messages, isEmpty, reason: '不应有解析错误：${report.messages}');
      expect(report.totalImported, 5);

      // ---- 比对 ----
      final w = await db.select(db.weightLogs).get();
      expect(w, hasLength(1));
      expect(w.single.weightKg, 55.4);
      expect(w.single.bodyFatPercent, 27.5);
      expect(w.single.note, '晨起');
      expect(w.single.recordedAt, DateTime(2026, 9, 2, 8, 30));

      final e = await db.select(db.exerciseLogs).get();
      expect(e, hasLength(1));
      expect(e.single.exerciseName, '快走');
      expect(e.single.minutes, 30);
      expect(e.single.kcal, 120.5);

      final m = await db.select(db.mealLogs).get();
      expect(m, hasLength(1));
      expect(m.single.mealType, 'lunch');
      expect(m.single.foodName, '鸡胸肉');
      expect(m.single.grams, 150);
      expect(m.single.kcal, 199.5);
      expect(m.single.proteinG, 36.9);

      final c = await db.select(db.periodCycles).get();
      expect(c, hasLength(1));
      expect(c.single.startDate, DateTime(2026, 8, 1));
      expect(c.single.endDate, DateTime(2026, 8, 5));
      expect(c.single.periodLength, 5);
      // 只有一段时没有"下一段"，cycleLength 重算为 null（进行中语义）
      expect(c.single.cycleLength, isNull);

      final d = await db.select(db.dailyRecords).get();
      final aug2 =
          d.firstWhere((r) => r.date == DateTime(2026, 8, 2));
      expect(aug2.isPeriodDay, isTrue);
      expect(aug2.flowLevel, 2);
      expect(aug2.painLevel, 1);
    });

    test('多段经期往返后 cycleLength 仍然是 28 天', () async {
      // 三段间隔 28 天（满足 15 天规则）
      for (final (s, e) in [
        (DateTime(2026, 8, 1), DateTime(2026, 8, 5)),
        (DateTime(2026, 8, 29), DateTime(2026, 9, 2)),
        (DateTime(2026, 9, 26), DateTime(2026, 9, 30)),
      ]) {
        await db.into(db.periodCycles).insert(PeriodCyclesCompanion.insert(
              startDate: s,
              endDate: Value(e),
              periodLength: const Value(5),
              isClosed: const Value(false),
            ));
      }

      final files = await const ExportService().exportAll(db, tmp);
      await db.delete(db.periodCycles).go();
      await const ImportService().importFiles(db, files);

      final rows = await (db.select(db.periodCycles)
            ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
          .get();
      expect(rows, hasLength(3));
      expect(rows[0].cycleLength, 28);
      expect(rows[1].cycleLength, 28);
      expect(rows[2].cycleLength, isNull); // 最后一段仍是进行中
    });
  });

  group('幂等与容错', () {
    test('同一批文件导两次：第二次全部 skipped，不产生重复', () async {
      await db.into(db.weightLogs).insert(WeightLogsCompanion.insert(
            recordedAt: DateTime(2026, 9, 2, 8, 30),
            weightKg: 55.4,
          ));
      await db.into(db.dailyRecords).insert(DailyRecordsCompanion.insert(
            date: DateTime(2026, 9, 3),
            isPeriodDay: const Value(true),
            flowLevel: const Value(2),
          ));
      final files = await const ExportService().exportAll(db, tmp);

      final first = await const ImportService().importFiles(db, files);
      // 体重已在库中 → 第一次就是 skipped
      expect(first.imported[ImportKind.weight] ?? 0, 0);
      // 逐日记录内容与库中一致 → 也算 skipped（幂等）
      expect(first.imported[ImportKind.periodDay] ?? 0, 0);
      expect(first.skipped[ImportKind.periodDay] ?? 0, 1);

      final second = await const ImportService().importFiles(db, files);
      expect(second.totalImported, 0, reason: '第二次不应再导入任何行');
      expect(await db.select(db.weightLogs).get(), hasLength(1));
      expect(await db.select(db.dailyRecords).get(), hasLength(1));
    });

    test('无法识别的表头 → 明确报错并跳过该文件', () async {
      final f = File('${tmp.path}/whatever.csv');
      await f.writeAsString('foo,bar\n1,2\n');

      final report = await const ImportService().importFiles(db, [f]);
      expect(report.messages, hasLength(1));
      expect(report.messages.first, contains('无法识别的表头'));
      expect(report.totalImported, 0);
    });

    test('非法行被跳过并记录原因，合法行照常导入', () async {
      final f = File('${tmp.path}/yueji_weight_manual.csv');
      // 第一行合法，第二行体重无法解析
      await f.writeAsString('记录时间,体重(kg),体脂率(%),备注\r\n'
          '2026-09-03 07:00,55,,\r\n'
          '2026-09-04 07:00,abc,,\r\n');

      final report = await const ImportService().importFiles(db, [f]);
      expect(report.imported[ImportKind.weight], 1);
      expect(report.skipped[ImportKind.weight], 1);
      expect(report.messages.single, contains('无法解析'));
      expect(await db.select(db.weightLogs).get(), hasLength(1));
    });

    test('经期段违反 15 天规则 → 跳过并给出具体原因', () async {
      final f = File('${tmp.path}/yueji_period_cycles_manual.csv');
      await f.writeAsString('开始日期,结束日期,经期天数,周期天数\r\n'
          '2026-09-01,2026-09-05,5,10\r\n'
          '2026-09-11,2026-09-15,5,10\r\n'); // 只隔 10 天

      final report = await const ImportService().importFiles(db, [f]);
      expect(report.imported[ImportKind.periodCycle], 1);
      expect(report.skipped[ImportKind.periodCycle], 1);
      expect(report.messages.single, contains('至少隔 15 天'));
      expect(await db.select(db.periodCycles).get(), hasLength(1));
    });
  });
}
