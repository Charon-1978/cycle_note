// lib/features/period/providers/period_providers.dart
//
// 经期模块的 Provider 链：
//   repository → cycles → prediction → 今日阶段
//
// 设计说明：预测是纯函数，放在 Provider 里每次从 cycles 推导，
// 不写库（PredictionCaches 表留给"需要留存历史预测"的场景，二期再接）。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database/app_database.dart';
import '../../../data/local/database/database_provider.dart';
import '../data/period_repository.dart';
import '../services/period_prediction_service.dart';

const PeriodPredictionService _predictor = PeriodPredictionService();

final periodRepositoryProvider = Provider<PeriodRepository>((ref) {
  return PeriodRepository(ref.watch(appDatabaseProvider));
});

/// 全部历史周期（升序）。
final cyclesProvider = FutureProvider<List<CycleInput>>((ref) {
  return ref.watch(periodRepositoryProvider).loadCycles();
});

/// 下一次经期预测。数据不足时为 null。
final predictionProvider = Provider<PeriodPrediction?>((ref) {
  final cycles = ref.watch(cyclesProvider).valueOrNull ?? const <CycleInput>[];
  if (cycles.isEmpty) return null;
  return _predictor.predict(cycles);
});

/// 今天所处的阶段。
final todayPhaseProvider = Provider<CyclePhase>((ref) {
  final cycles = ref.watch(cyclesProvider).valueOrNull ?? const <CycleInput>[];
  final prediction = ref.watch(predictionProvider);
  return _predictor.phaseOf(
    DateTime.now(),
    prediction: prediction,
    recordedCycles: cycles,
  );
});

/// 今天是否在经期中（已记录）。
final inPeriodProvider = FutureProvider<bool>((ref) async {
  // 依赖 cycles，保证记录后能重算
  ref.watch(cyclesProvider);
  return ref.watch(periodRepositoryProvider).isInPeriod(DateTime.now());
});

/// 今天处于经期第几天（1-based）；不在经期则为 null。
final currentPeriodDayProvider = Provider<int?>((ref) {
  final cycles = ref.watch(cyclesProvider).valueOrNull ?? const <CycleInput>[];
  if (cycles.isEmpty) return null;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final c in cycles.reversed) {
    final start = DateTime(c.start.year, c.start.month, c.start.day);
    if (today.isBefore(start)) continue;
    if (c.end != null) {
      final end = DateTime(c.end!.year, c.end!.month, c.end!.day);
      if (today.isAfter(end)) return null;
    }
    return today.difference(start).inDays + 1;
  }
  return null;
});

/// 今天的每日记录（含经量、痛经等级）。
final todayRecordProvider = FutureProvider<DailyRecord?>((ref) async {
  ref.watch(cyclesProvider);
  return ref.watch(periodRepositoryProvider).recordOf(DateTime.now());
});
