// lib/features/weight_loss/services/import_service.dart
//
// CSV 导入（P5-1）：把 ExportService 导出的五类数据读回来。
//
// 为什么必须是 CSV 而不是"复制 .sqlite 文件"：
//   我们的库用 SQLCipher 加密，密钥在 flutter_secure_storage
//   （Android Keystore，不可导出）。换到新设备后密钥不同，
//   旧库文件**在物理上就打不开**。所以跨设备迁移只能走明文 CSV。
//   库文件级恢复只对「同一设备、升级失败回滚」有意义（见 DbBackup）。
//
// 导入纪律：
//   1) 严格模式——经期段同样走 PeriodHistoryEditor 的校验（15 天间隔、长度 2–10）。
//      被拒的行计入 skipped 并给出原因，**不静默丢弃**；
//   2) 幂等——按业务键去重，重复导入同一批文件不会产生第二份数据；
//   3) 单事务——中途失败整体回滚，不留半截数据。
//
// 解析与写入分离：parse/decode 是纯函数，可单测；apply 才碰数据库。

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../../../data/local/database/app_database.dart';
import '../../period/services/period_history_editor.dart';
import '../../period/services/period_prediction_service.dart' show CycleInput;

/// 一张 CSV 表。
class CsvTable {
  const CsvTable({required this.header, required this.rows});

  final List<String> header;
  final List<List<String>> rows;

  int indexOf(String name) => header.indexOf(name);

  String? cell(List<String> row, String column) {
    final i = indexOf(column);
    if (i < 0 || i >= row.length) return null;
    final v = row[i].trim();
    return v.isEmpty ? null : v;
  }
}

enum ImportKind { weight, exercise, meal, periodCycle, periodDay, unknown }

/// 导入统计。
class ImportReport {
  const ImportReport({
    required this.imported,
    required this.skipped,
    required this.messages,
  });

  final Map<ImportKind, int> imported;
  final Map<ImportKind, int> skipped;
  final List<String> messages;

  int get totalImported => imported.values.fold(0, (a, b) => a + b);
  int get totalSkipped => skipped.values.fold(0, (a, b) => a + b);
  bool get ok => messages.isEmpty;

  static ImportReport empty() => const ImportReport(
        imported: {},
        skipped: {},
        messages: [],
      );
}

class ImportService {
  const ImportService();

  // ---------------- 解析（纯函数） ----------------

  /// 去掉 UTF-8 BOM 并解码。
  static String decodeBytes(List<int> bytes) {
    var b = bytes;
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
      b = b.sublist(3);
    }
    return utf8.decode(b, allowMalformed: true);
  }

  /// RFC 4180 解析：支持引号字段、转义引号、CRLF/LF、空行。
  static CsvTable parseCsv(String text) {
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;

    void endField() {
      row.add(field.toString());
      field = StringBuffer();
    }

    void endRow() {
      endField();
      // 整行为空（只有一个空字段）时跳过，容忍文件末尾的空行
      if (!(row.length == 1 && row.first.isEmpty)) rows.add(row);
      row = <String>[];
    }

    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
        continue;
      }
      if (c == '"') {
        inQuotes = true;
      } else if (c == ',') {
        endField();
      } else if (c == '\r') {
        // 交给 \n 处理；单独的 \r 也视为换行
        if (i + 1 >= text.length || text[i + 1] != '\n') endRow();
      } else if (c == '\n') {
        endRow();
      } else {
        field.write(c);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) endRow();

    if (rows.isEmpty) return const CsvTable(header: [], rows: []);
    return CsvTable(header: rows.first, rows: rows.sublist(1));
  }

  /// 按表头签名识别文件类型（顺序敏感：经期表头最独特，先判）。
  static ImportKind detect(CsvTable table) {
    final h = table.header.map((e) => e.trim()).toSet();
    if (h.contains('开始日期')) return ImportKind.periodCycle;
    if (h.contains('经期日')) return ImportKind.periodDay;
    if (h.contains('体重(kg)')) return ImportKind.weight;
    if (h.contains('运动名称')) return ImportKind.exercise;
    if (h.contains('餐次')) return ImportKind.meal;
    return ImportKind.unknown;
  }

  // ---------------- 写入 ----------------

  /// 导入一批文件。单事务；返回统计。
  Future<ImportReport> importFiles(AppDatabase db, List<File> files) async {
    final imported = <ImportKind, int>{};
    final skipped = <ImportKind, int>{};
    final messages = <String>[];

    // 先按"周期 → 每日 → 体重/运动/饮食"排序：周期导入会重建经期日标记，
    // 之后再写每日强度才不会被打架。
    final parsed = <(ImportKind, CsvTable, String)>[];
    for (final f in files) {
      final table = parseCsv(decodeBytes(f.readAsBytesSync()));
      final kind = detect(table);
      if (kind == ImportKind.unknown) {
        messages.add('${f.uri.pathSegments.last}：无法识别的表头（跳过整个文件）');
        continue;
      }
      parsed.add((kind, table, f.uri.pathSegments.last));
    }
    parsed.sort((a, b) => _kindOrder(a.$1).compareTo(_kindOrder(b.$1)));

    await db.transaction(() async {
      for (final (kind, table, name) in parsed) {
        switch (kind) {
          case ImportKind.periodCycle:
            await _importCycles(db, table, imported, skipped, messages, name);
          case ImportKind.periodDay:
            await _importDays(db, table, imported, skipped, messages, name);
          case ImportKind.weight:
            await _importWeights(db, table, imported, skipped, messages, name);
          case ImportKind.exercise:
            await _importExercises(db, table, imported, skipped, messages, name);
          case ImportKind.meal:
            await _importMeals(db, table, imported, skipped, messages, name);
          case ImportKind.unknown:
            break;
        }
      }
    });

    return ImportReport(
      imported: imported,
      skipped: skipped,
      messages: messages,
    );
  }

  static int _kindOrder(ImportKind k) => switch (k) {
        ImportKind.periodCycle => 0,
        ImportKind.periodDay => 1,
        ImportKind.weight => 2,
        ImportKind.exercise => 3,
        ImportKind.meal => 4,
        ImportKind.unknown => 5,
      };

  Future<void> _importWeights(
    AppDatabase db,
    CsvTable table,
    Map<ImportKind, int> imported,
    Map<ImportKind, int> skipped,
    List<String> messages,
    String fileName,
  ) async {
    final existing = await db.select(db.weightLogs).get();
    final keys = {
      for (final r in existing) '${_key(r.recordedAt)}|${r.weightKg}',
    };

    for (final row in table.rows) {
      final at = _parseTime(table.cell(row, '记录时间'));
      final kg = double.tryParse(table.cell(row, '体重(kg)') ?? '');
      if (at == null || kg == null) {
        _inc(skipped, ImportKind.weight);
        messages.add('$fileName：跳过一行体重（时间或数值无法解析）');
        continue;
      }
      final k = '${_key(at)}|$kg';
      if (keys.contains(k)) {
        _inc(skipped, ImportKind.weight);
        continue;
      }
      keys.add(k);
      await db.into(db.weightLogs).insert(
            WeightLogsCompanion.insert(
              recordedAt: at,
              weightKg: kg,
              bodyFatPercent: Value(
                double.tryParse(table.cell(row, '体脂率(%)') ?? ''),
              ),
              note: Value(table.cell(row, '备注') ?? ''),
            ),
          );
      _inc(imported, ImportKind.weight);
    }
  }

  Future<void> _importExercises(
    AppDatabase db,
    CsvTable table,
    Map<ImportKind, int> imported,
    Map<ImportKind, int> skipped,
    List<String> messages,
    String fileName,
  ) async {
    final existing = await db.select(db.exerciseLogs).get();
    final keys = {
      for (final r in existing)
        '${_key(r.recordedAt)}|${r.exerciseName}|${r.minutes}',
    };

    for (final row in table.rows) {
      final at = _parseTime(table.cell(row, '记录时间'));
      final name = table.cell(row, '运动名称');
      final minutes = int.tryParse(table.cell(row, '时长(分钟)') ?? '');
      if (at == null || name == null || minutes == null) {
        _inc(skipped, ImportKind.exercise);
        messages.add('$fileName：跳过一行运动（时间/名称/时长无法解析）');
        continue;
      }
      final k = '${_key(at)}|$name|$minutes';
      if (keys.contains(k)) {
        _inc(skipped, ImportKind.exercise);
        continue;
      }
      keys.add(k);
      await db.into(db.exerciseLogs).insert(
            ExerciseLogsCompanion.insert(
              recordedAt: at,
              // 导出文件里没有运动 code，用名称造一个稳定 code
              exerciseCode: 'imported:$name',
              exerciseName: name,
              // MET 未导出：用 3.5（步行量级）占位，热量以 CSV 值为准
              met: 3.5,
              minutes: minutes,
              weightKgAtTime:
                  double.tryParse(table.cell(row, '当时体重(kg)') ?? '') ?? 0,
              kcal: double.tryParse(table.cell(row, '消耗(kcal)') ?? '') ?? 0,
            ),
          );
      _inc(imported, ImportKind.exercise);
    }
  }

  Future<void> _importMeals(
    AppDatabase db,
    CsvTable table,
    Map<ImportKind, int> imported,
    Map<ImportKind, int> skipped,
    List<String> messages,
    String fileName,
  ) async {
    final existing = await db.select(db.mealLogs).get();
    final keys = {
      for (final r in existing)
        '${_key(r.recordedAt)}|${r.foodName}|${r.grams}',
    };
    const labels = {
      '早餐': 'breakfast',
      '午餐': 'lunch',
      '晚餐': 'dinner',
      '加餐': 'snack',
    };

    for (final row in table.rows) {
      final at = _parseTime(table.cell(row, '记录时间'));
      final food = table.cell(row, '食物');
      final grams = double.tryParse(table.cell(row, '克数(g)') ?? '');
      final mealLabel = table.cell(row, '餐次');
      if (at == null || food == null || grams == null) {
        _inc(skipped, ImportKind.meal);
        messages.add('$fileName：跳过一行饮食（时间/食物/克数无法解析）');
        continue;
      }
      final k = '${_key(at)}|$food|$grams';
      if (keys.contains(k)) {
        _inc(skipped, ImportKind.meal);
        continue;
      }
      keys.add(k);
      await db.into(db.mealLogs).insert(
            MealLogsCompanion.insert(
              recordedAt: at,
              mealType: labels[mealLabel] ?? 'lunch',
              foodCode: 'imported:$food',
              foodName: food,
              grams: grams,
              kcal: double.tryParse(table.cell(row, '热量(kcal)') ?? '') ?? 0,
              proteinG: Value(
                  double.tryParse(table.cell(row, '蛋白质(g)') ?? '') ?? 0),
              fatG: Value(double.tryParse(table.cell(row, '脂肪(g)') ?? '') ?? 0),
              carbG:
                  Value(double.tryParse(table.cell(row, '碳水(g)') ?? '') ?? 0),
            ),
          );
      _inc(imported, ImportKind.meal);
    }
  }

  /// 经期周期：逐段走 PeriodHistoryEditor（严格校验），保证 cycleLength 重算正确。
  Future<void> _importCycles(
    AppDatabase db,
    CsvTable table,
    Map<ImportKind, int> imported,
    Map<ImportKind, int> skipped,
    List<String> messages,
    String fileName,
  ) async {
    const editor = PeriodHistoryEditor();

    // 按开始日期升序导入，否则中间插入会反复重算、日志也会乱
    final rows = [...table.rows]..sort((a, b) {
        final da = _parseDate(table.cell(a, '开始日期'));
        final db2 = _parseDate(table.cell(b, '开始日期'));
        if (da == null || db2 == null) return 0;
        return da.compareTo(db2);
      });

    for (final row in rows) {
      final start = _parseDate(table.cell(row, '开始日期'));
      if (start == null) {
        _inc(skipped, ImportKind.periodCycle);
        messages.add('$fileName：跳过一段经期（开始日期无法解析）');
        continue;
      }
      final end = _parseDate(table.cell(row, '结束日期'));

      final existing = await db.select(db.periodCycles).get();
      // 已存在同开始日的段 → 视为重复（幂等）
      if (existing.any((r) => _sameDay(r.startDate, start))) {
        _inc(skipped, ImportKind.periodCycle);
        continue;
      }

      final current = existing.map(_toCycleInput).toList(growable: false);

      final edit = editor.upsert(
        existing: current,
        start: start,
        end: end,
      );
      if (!edit.ok) {
        _inc(skipped, ImportKind.periodCycle);
        messages.add(
          '$fileName：${start.month}月${start.day}日 这段未导入 —— ${edit.error}',
        );
        continue;
      }
      await _writeCycles(db, edit);
      _inc(imported, ImportKind.periodCycle);
    }
  }

  Future<void> _importDays(
    AppDatabase db,
    CsvTable table,
    Map<ImportKind, int> imported,
    Map<ImportKind, int> skipped,
    List<String> messages,
    String fileName,
  ) async {
    final cycles = await db.select(db.periodCycles).get();
    int cycleIdFor(DateTime d) {
      for (final c in cycles) {
        final s = _dateOnly(c.startDate);
        final e = c.endDate == null
            ? s.add(Duration(days: (c.periodLength ?? 5) - 1))
            : _dateOnly(c.endDate!);
        if (!d.isBefore(s) && !d.isAfter(e)) return c.id;
      }
      return 0;
    }

    for (final row in table.rows) {
      final day = _parseDate(table.cell(row, '日期'));
      if (day == null) {
        _inc(skipped, ImportKind.periodDay);
        messages.add('$fileName：跳过一行逐日记录（日期无法解析）');
        continue;
      }
      final isPeriod = (table.cell(row, '经期日') ?? '') == '是';
      final flow = int.tryParse(table.cell(row, '经量') ?? '');
      final pain = int.tryParse(table.cell(row, '痛经') ?? '');

      final existing = await (db.select(db.dailyRecords)
            ..where((t) => t.date.equals(day)))
          .getSingleOrNull();

      if (existing == null) {
        await db.into(db.dailyRecords).insert(
              DailyRecordsCompanion.insert(
                date: day,
                isPeriodDay: Value(isPeriod),
                cycleId: Value(isPeriod ? cycleIdFor(day) : null),
                flowLevel: Value(flow),
                painLevel: Value(pain),
              ),
            );
      } else {
        // 幂等：同内容不重复计入「导入」，否则同一批文件导两次会显示"又导了 N 条"
        final sameAsExisting = existing.isPeriodDay == isPeriod &&
            (flow == null || existing.flowLevel == flow) &&
            (pain == null || existing.painLevel == pain);
        if (sameAsExisting) {
          _inc(skipped, ImportKind.periodDay);
          continue;
        }
        await (db.update(db.dailyRecords)
              ..where((t) => t.date.equals(day)))
            .write(DailyRecordsCompanion(
          isPeriodDay: Value(isPeriod),
          flowLevel: flow == null ? const Value.absent() : Value(flow),
          painLevel: pain == null ? const Value.absent() : Value(pain),
          updatedAt: Value(DateTime.now()),
        ));
      }
      _inc(imported, ImportKind.periodDay);
    }
  }

  /// 把编辑结果写回周期表（与 PeriodRepository._applyEdit 的写库部分同构）。
  Future<void> _writeCycles(AppDatabase db, PeriodEditResult edit) async {
    final rows = await db.select(db.periodCycles).get();
    for (final c in edit.cycles) {
      final idx = rows.indexWhere((r) => _sameDay(r.startDate, c.start));
      if (idx < 0) {
        await db.into(db.periodCycles).insert(
              PeriodCyclesCompanion.insert(
                startDate: _dateOnly(c.start),
                endDate: Value(c.end),
                cycleLength: Value(c.cycleLength),
                periodLength: Value(c.periodLength),
                isClosed: Value(c.cycleLength != null),
              ),
            );
      } else {
        await (db.update(db.periodCycles)
              ..where((t) => t.id.equals(rows[idx].id)))
            .write(PeriodCyclesCompanion(
          endDate: Value(c.end),
          cycleLength: Value(c.cycleLength),
          periodLength: Value(c.periodLength),
          isClosed: Value(c.cycleLength != null),
          updatedAt: Value(DateTime.now()),
        ));
      }
    }
  }

  // ---------------- 工具 ----------------

  static DateTime? _parseTime(String? s) {
    if (s == null) return null;
    final t = s.trim().replaceFirst(' ', 'T');
    return DateTime.tryParse(t);
  }

  static DateTime? _parseDate(String? s) {
    if (s == null) return null;
    final t = DateTime.tryParse(s.trim());
    return t == null ? null : _dateOnly(t);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static CycleInput _toCycleInput(PeriodCycle r) => CycleInput(
        start: _dateOnly(r.startDate),
        end: r.endDate == null ? null : _dateOnly(r.endDate!),
        cycleLength: r.cycleLength,
        periodLength: r.periodLength,
      );

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 去重键：分钟精度（导出格式只到分钟）
  static String _key(DateTime t) =>
      '${t.year}-${t.month}-${t.day} ${t.hour}:${t.minute}';

  static void _inc(Map<ImportKind, int> map, ImportKind k) {
    map[k] = (map[k] ?? 0) + 1;
  }
}
