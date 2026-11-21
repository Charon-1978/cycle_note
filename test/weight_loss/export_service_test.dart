// test/weight_loss/export_service_test.dart
//
// P2-6「CSV 导出」验收，逐条对应手册：
//   · 三类 CSV（体重/运动/饮食）列顺序与表头锁死
//   · **UTF-8 BOM** 开头（Excel 中文不乱码的前提）
//   · 行结束符 CRLF（Excel 解析惯例）
//   · 字段含单位（表头带 kg/kcal/g）
//   · 含逗号/引号的字段按 RFC 4180 加引号
//   · 不含任何密钥/内部路径
//
// build*Csv 是纯函数，直接断言字符串内容；
// exportAll 的 IO 路径单独一条，写到临时目录后按字节读回验证 BOM。

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/features/weight_loss/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 迷你 RFC 4180 字段计数：引号内的逗号不是分隔符。
  int csvFieldCount(String row) {
    var fields = 1;
    var inQuotes = false;
    for (var i = 0; i < row.length; i++) {
      final c = row[i];
      if (c == '"') {
        if (inQuotes && i + 1 < row.length && row[i + 1] == '"') {
          i++; // 转义引号，跳过
        } else {
          inQuotes = !inQuotes;
        }
      } else if (c == ',' && !inQuotes) {
        fields++;
      }
    }
    return fields;
  }

  late AppDatabase db;
  setUp(() {
    // 迁移会话标记走 SharedPreferences，测试环境必须给 mock
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  const service = ExportService();

  group('build*Csv（纯函数）', () {
    test('体重：表头含单位，行结束符是 CRLF，数值去尾零', () async {
      await db.into(db.weightLogs).insert(
            WeightLogsCompanion.insert(
              recordedAt: DateTime(2026, 1, 5, 8, 30),
              weightKg: 62.0,
              bodyFatPercent: const Value(28.5),
              note: const Value('晨起空腹'),
            ),
          );
      final csv = service.buildWeightCsv(await db.select(db.weightLogs).get());

      expect(csv.startsWith('记录时间,体重(kg),体脂率(%),备注'), isTrue);
      expect(csv.contains('\r\n'), isTrue);
      expect(csv.contains('2026-01-05 08:30,62,28.5,晨起空腹\r\n'), isTrue);
      // 体脂率为空的行要留出空列，不能挤压
    });

    test('体重：体脂率为空 → 该列留空', () async {
      await db.into(db.weightLogs).insert(
            WeightLogsCompanion.insert(
              recordedAt: DateTime(2026, 1, 5),
              weightKg: 61.5,
            ),
          );
      final csv = service.buildWeightCsv(await db.select(db.weightLogs).get());
      expect(csv, contains('2026-01-05 00:00,61.5,,\r\n'));
    });

    test('运动：列顺序与数值', () async {
      await db.into(db.exerciseLogs).insert(
            ExerciseLogsCompanion.insert(
              recordedAt: DateTime(2026, 1, 6, 19, 0),
              exerciseCode: 'walking',
              exerciseName: '快走',
              met: 4.3,
              minutes: 30,
              weightKgAtTime: 62,
              kcal: 120.5,
            ),
          );
      final csv =
          service.buildExerciseCsv(await db.select(db.exerciseLogs).get());
      expect(
        csv.startsWith('记录时间,运动名称,时长(分钟),消耗(kcal),当时体重(kg)'),
        isTrue,
      );
      expect(csv, contains('2026-01-06 19:00,快走,30,120.5,62\r\n'));
    });

    test('饮食：餐次译成中文，宏量列齐全', () async {
      await db.into(db.mealLogs).insert(
            MealLogsCompanion.insert(
              recordedAt: DateTime(2026, 1, 6, 12, 20),
              mealType: 'lunch',
              foodCode: 'chicken_breast',
              foodName: '鸡胸肉',
              grams: 150,
              kcal: 199.5,
              proteinG: const Value(36.9),
              fatG: const Value(3.75),
              carbG: const Value(0.9),
            ),
          );
      final csv = service.buildMealCsv(await db.select(db.mealLogs).get());
      expect(
        csv.startsWith('记录时间,餐次,食物,克数(g),热量(kcal),蛋白质(g),脂肪(g),碳水(g)'),
        isTrue,
      );
      expect(csv, contains('2026-01-06 12:20,午餐,鸡胸肉,150,199.5,36.9,3.75,0.9\r\n'));
    });

    test('含逗号/引号/换行的字段按 RFC 4180 转义', () async {
      await db.into(db.weightLogs).insert(
            WeightLogsCompanion.insert(
              recordedAt: DateTime(2026, 1, 7),
              weightKg: 62,
              note: const Value('感冒了, 多喝"水"\n注意休息'),
            ),
          );
      final csv = service.buildWeightCsv(await db.select(db.weightLogs).get());
      // 换行被压成空格；逗号和引号触发整字段加引号，引号翻倍
      expect(csv, contains('"感冒了, 多喝""水"" 注意休息"'));
      // 字段数不因内嵌逗号而错位：引号内的逗号不是分隔符
      final row = csv.split('\r\n').firstWhere((l) => l.contains('62'));
      expect(csvFieldCount(row), 4, reason: '行应为 4 个字段：$row');
    });
  });

  group('exportAll（IO）', () {
    late Directory tmp;
    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('yueji_export_test');
    });
    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    test('写出 5 个文件，文件字节以 UTF-8 BOM 开头，无密钥内容', () async {
      await db.into(db.weightLogs).insert(
            WeightLogsCompanion.insert(
              recordedAt: DateTime(2026, 1, 5),
              weightKg: 62,
            ),
          );

      final files = await service.exportAll(db, tmp);
      // 体重 / 运动 / 饮食 / 经期周期 / 经期逐日
      expect(files, hasLength(5));
      expect(files.every((f) => f.existsSync()), isTrue);

      for (final f in files) {
        final bytes = f.readAsBytesSync();
        // BOM = EF BB BF
        expect(bytes[0], 0xEF, reason: '${f.path} 缺 UTF-8 BOM');
        expect(bytes[1], 0xBB);
        expect(bytes[2], 0xBF);
        final text = utf8.decode(bytes.sublist(3));
        expect(text.contains('\r\n'), isTrue);

        // 数据主权红线：导出文件里不允许出现密钥类内容
        final lower = text.toLowerCase();
        for (final banned in ['apikey', 'api_key', 'token', 'secret', 'password']) {
          expect(lower.contains(banned), isFalse,
              reason: '${f.path} 出现敏感字样 $banned');
        }
      }

      expect(files[0].path.contains('weight'), isTrue);
      expect(files[1].path.contains('exercise'), isTrue);
      expect(files[2].path.contains('meal'), isTrue);
      expect(files[3].path.contains('period_cycles'), isTrue);
      expect(files[4].path.contains('period_days'), isTrue);
    });

    test('空库也能导出（只有表头，不崩）', () async {
      final files = await service.exportAll(db, tmp);
      expect(files, hasLength(5));
      final text = utf8.decode(files[0].readAsBytesSync().sublist(3));
      expect(text, '记录时间,体重(kg),体脂率(%),备注\r\n');
    });
  });
}
