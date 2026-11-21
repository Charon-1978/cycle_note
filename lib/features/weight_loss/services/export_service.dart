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

  // ---------- 导出（IO） ----------

  /// 三类各导一个文件到 [outDir]，返回写入的文件路径（顺序：体重/运动/饮食）。
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

  /// 数值统一两位以内小数，去掉无意义的尾零（0.30 → 0.3）。
  String _num(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}
