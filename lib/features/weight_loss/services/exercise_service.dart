// lib/features/weight_loss/services/exercise_service.dart
//
// 运动能耗计算。基于 MET（代谢当量）。
//
// 公式（ACSM 标准）：
//   kcal = MET × 3.5 × 体重(kg) / 200 × 时长(min)
//   等价于 kcal = MET × 体重(kg) × 时长(h)
//
// 注意：MET 反映的是「运动时的代谢倍数」，
// 净消耗（扣掉躺着也会消耗的那部分）应为 (MET − 1)。
// 本实现提供两种口径，默认用总消耗（与主流 App 一致）。

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;


/// 一条运动定义
class ExerciseDef {
  const ExerciseDef({
    required this.code,
    required this.name,
    required this.met,
  });

  final String code;
  final String name;
  final double met;
}

/// 一条运动记录
class ExerciseRecord {
  const ExerciseRecord({
    required this.def,
    required this.minutes,
    required this.weightKgAtTime,
    this.date,
  });

  final ExerciseDef def;
  final int minutes;

  /// 记录当时的体重——体重会变，用历史体重算更准
  final double weightKgAtTime;
  final DateTime? date;

  double get kcal => ExerciseService.burn(
        met: def.met,
        weightKg: weightKgAtTime,
        minutes: minutes,
      );
}

class ExerciseService {
  ExerciseService._();
  static final ExerciseService instance = ExerciseService._();

  List<ExerciseDef> _defs = const [];
  bool _loaded = false;

  List<ExerciseDef> get all => _defs;

  /// 从 assets 载入 MET 表（首次调用时加载并缓存）
  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/exercise_met.csv');
    final lines = const LineSplitter().convert(raw);
    final out = <ExerciseDef>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');
      if (parts.length < 3) continue;
      final met = double.tryParse(parts[2].trim());
      if (met == null || met <= 0) continue;
      out.add(ExerciseDef(
        code: parts[0].trim(),
        name: parts[1].trim(),
        met: met,
      ));
    }
    _defs = List.unmodifiable(out);
    _loaded = true;
  }

  List<ExerciseDef> search(String keyword) {
    if (keyword.trim().isEmpty) return _defs;
    final k = keyword.trim().toLowerCase();
    return _defs
        .where((e) =>
            e.name.toLowerCase().contains(k) ||
            e.code.toLowerCase().contains(k))
        .toList(growable: false);
  }

  /// 核心：MET → kcal
  /// [net] 为 true 时扣除静息代谢（净消耗），默认 false。
  static double burn({
    required double met,
    required double weightKg,
    required int minutes,
    bool net = false,
  }) {
    if (minutes <= 0 || weightKg <= 0) return 0;
    final effectiveMet = net ? (met - 1).clamp(0.0, 30.0) : met;
    // MET × 3.5 × kg / 200 × min
    return effectiveMet * 3.5 * weightKg / 200.0 * minutes;
  }

  /// 反推：想消耗 [targetKcal]，在给定体重下需要多少分钟
  static int minutesFor({
    required double met,
    required double weightKg,
    required double targetKcal,
  }) {
    if (met <= 0 || weightKg <= 0 || targetKcal <= 0) return 0;
    final perMin = met * 3.5 * weightKg / 200.0;
    if (perMin <= 0) return 0;
    return (targetKcal / perMin).ceil();
  }

  /// 展示用：某运动「约 X kcal / 60 分钟」
  static int kcalPerHour({
    required double met,
    required double weightKg,
    bool net = false,
  }) =>
      burn(met: met, weightKg: weightKg, minutes: 60, net: net).round();

  /// 汇总一段时间内的运动消耗
  static double sumKcal(Iterable<ExerciseRecord> records) =>
      records.fold(0.0, (s, r) => s + r.kcal);
}
