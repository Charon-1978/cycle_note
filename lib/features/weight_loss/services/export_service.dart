// lib/features/weight_loss/services/export_service.dart
//
// CSV 导出（P2-6）：体重 / 运动 / 饮食三类。
//
// 硬性约定（手册 P2-6 验收 + Gate 2）：
//   1) **UTF-8 BOM 开头** —— 没有 BOM 时 Excel 会按 ANSI 猜编码，
//      中文列名直接乱码；这是"可被 Excel 正确解析"的前提。
//   2) **行结束符 CRLF** —— Excel 对纯 LF 的多行解析不一致。
//   3) **列顺序从 v1 起锁死** —— 只允许在表尾追加新列，
//      顺序向后兼容；重排列会让旧导入脚本/表格公式错位。
//   4) **字段含单位** —— 表头带 (kg)/(kcal)/(g)，拷到别处仍可读。
//   5) **只含用户数据，不含任何密钥/Token/内部路径** —— 导出文件可能被
//      用户随手发给别人，敏感内容一律不进 CSV。
//
// 纯函数与 IO 分离：build*Csv 可以单测；文件写入只在 export* 里。

import 'dart:convert';
import 'dart:io';

import '../../../data/local/database/app_database.dart';

class ExportService {
  const ExportService();

  // ---------- 表头（v1，锁死顺序） ----------

  static const List<String> _weightHeader = [
    '记录时间',
    '体重(kg)',
    '体脂率(%)',
    '备注',
  ];
  static const List<String> _exerciseHeader = [
    '记录时间',
    '运动名称',
    '时长(分钟)',
    '消耗(kcal)',
    '当时体重(kg)',
  ];
  static const List<String> _mealHeader = [
    '记录时间',
    '餐次',
    '食物',
    '克数(g)',
    '热量(kcal)',
    '蛋白质(g)',
    '脂肪(g)',
    '碳水(g)',
  ];

  static const List<String> _periodCycleHeader = [
    '开始日期',
    '结束日期',
    '经期天数',
    '周期天数',
  ];
  static const List<String> _periodDayHeader = [
    '日期',
    '经期日',
    '经量',
    '痛经',
  ];

  static const String _bom = '\uFEFF';

  /// 餐次代码 → 展示名。与 food_log_page 的 kMealLabels 同源含义，
  /// 这里独立一份常量是为了让导出不依赖 UI 文件。
  static const Map<String, String> kMealTypeLabels = {
    'breakfast': '早餐',
    'lunch': '午餐',
    'dinner': '晚餐',
    'snack': '加餐',
  };

  // ---------- CSV 构建（纯函数） ----------

  String buildWeightCsv(Iterable<WeightLog> rows) {
    return _assemble(_weightHeader, [
      for (final r in rows)
        [
          _fmtTime(r.recordedAt),
          _num(r.weightKg),
          // Dart 局部变量提升：先拷非空再判空，避免链上重复判
          if (r.bodyFatPercent == null) '' else _num(r.bodyFatPercent!),
          r.note,
        ],
    ]);
  }

  String buildExerciseCsv(Iterable<ExerciseLog> rows) {
    return _assemble(_exerciseHeader, [
      for (final r in rows)
        [
          _fmtTime(r.recordedAt),
          r.exerciseName,
          r.minutes.toString(),
          _num(r.kcal),
          _num(r.weightKgAtTime),
        ],
    ]);
  }

  String buildMealCsv(Iterable<MealLog> rows) {
    return _assemble(_mealHeader, [
      for (final r in rows)
        [
          _fmtTime(r.recordedAt),
          kMealTypeLabels[r.mealType] ?? r.mealType,
          r.foodName,
          _num(r.grams),
          _num(r.kcal),
          _num(r.proteinG),
          _num(r.fatG),
          _num(r.carbG),
        ],
    ]);
  }

  /// 经期周期（一段经期一行）。
  ///
  /// 结束日期空 = 进行中；周期天数空 = 最后一段（还没有下一段可算）。
  /// 导入时会用 PeriodHistoryEditor 重算这两个字段，所以它们只是「参考值」，
  /// 真正的事实是开始/结束日期。
  String buildPeriodCycleCsv(Iterable<PeriodCycle> rows) {
    final sorted = [...rows]..sort((a, b) => a.startDate.compareTo(b.startDate));
    return _assemble(_periodCycleHeader, [
      for (final r in sorted)
        [
          _fmtDate(r.startDate),
          r.endDate == null ? '' : _fmtDate(r.endDate!),
          r.periodLength?.toString() ?? '',
          r.cycleLength?.toString() ?? '',
        ],
    ]);
  }

  /// 经期逐日记录（只导出真正有内容的行：经期日或填过经量/痛经）。
  String buildPeriodDayCsv(Iterable<DailyRecord> rows) {
    final kept = rows
        .where((r) =>
            r.isPeriodDay ||
            r.flowLevel != null ||
            r.painLevel != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return _assemble(_periodDayHeader, [
      for (final r in kept)
        [
          _fmtDate(r.date),
          r.isPeriodDay ? '是' : '否',
          r.flowLevel?.toString() ?? '',
          r.painLevel?.toString() ?? '',
        ],
    ]);
  }

  // ---------- 导出（IO） ----------

  /// 把五类数据各导一个文件到 [outDir]，返回写入路径
  /// （顺序：体重 / 运动 / 饮食 / 经期周期 / 经期逐日）。
  ///
  /// 为什么把经期也纳入：Gate 2 的验收是「导出 → 清空 → 导入 往返一致」，
  /// 只导减肥数据的话，换机后经期历史（产品的另一半）会整体丢失。
  ///
  /// 文件名带导出时刻，多次导出互不覆盖；不删除旧导出——数据主权工具
  /// 默认"只增不删"，删除交给用户自己做。
  Future<List<File>> exportAll(AppDatabase db, Directory outDir) async {
    await outDir.create(recursive: true);
    final now = DateTime.now();
    final stamp = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';

    final weights = await db.select(db.weightLogs).get();
    final exercises = await db.select(db.exerciseLogs).get();
    final meals = await db.select(db.mealLogs).get();
    final cycles = await db.select(db.periodCycles).get();
    final days = await db.select(db.dailyRecords).get();

    Future<File> write(String name, String content) async {
      final f = File('${outDir.path}${Platform.pathSeparator}$name');
      // 手动写 UTF-8 BOM：dart:io 的 writeAsString 不带 BOM
      final bytes = <int>[
        ...utf8.encode(_bom),
        ...utf8.encode(content),
      ];
      return f.writeAsBytes(bytes, flush: true);
    }

    return [
      await write('yueji_weight_$stamp.csv', buildWeightCsv(weights)),
      await write('yueji_exercise_$stamp.csv', buildExerciseCsv(exercises)),
      await write('yueji_meal_$stamp.csv', buildMealCsv(meals)),
      await write(
          'yueji_period_cycles_$stamp.csv', buildPeriodCycleCsv(cycles)),
      await write('yueji_period_days_$stamp.csv', buildPeriodDayCsv(days)),
    ];
  }

  // ---------- 内部 ----------

  String _assemble(List<String> header, List<List<String>> rows) {
    final b = StringBuffer();
    b.write(_row(header));
    for (final r in rows) {
      b.write(_row(r));
    }
    return b.toString();
  }

  String _row(List<String> cells) {
    // Excel 惯例：行结束符 CRLF
    return '${cells.map(_cell).join(',')}\r\n';
  }

  /// RFC 4180：含逗号/引号/换行/前导空格的字段加引号，引号翻倍。
  String _cell(String raw) {
    final v = raw.replaceAll('\r', ' ').replaceAll('\n', ' ');
    final needsQuote =
        v.contains(',') || v.contains('"') || v != v.trim();
    if (!needsQuote) return v;
    return '"${v.replaceAll('"', '""')}"';
  }

  String _fmtTime(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  /// 只到日期（经期表用；时分秒对经期无意义，还会让导入解析变复杂）。
  String _fmtDate(DateTime t) =>
      '${t.year}-${t.month.toString().padLeft(2, '0')}-'
      '${t.day.toString().padLeft(2, '0')}';

  /// 数值统一两位以内小数，去掉无意义的尾零（0.30 → 0.3）。
  String _num(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}
