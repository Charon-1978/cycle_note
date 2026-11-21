// lib/features/weight_loss/pages/exercise_log_page.dart
//
// 运动记录（P1-5）。
//
// 两个容易做错的地方，这里刻意做对：
//   1) 保存时必须写**当时的体重**（weightKgAtTime）。体重会变，
//      MET 公式里的 kg 一变，同样的运动消耗就不同 —— 历史记录不能被重算。
//   2) 列表按日期分组，不给一坨平铺流水账。用户看运动记录的场景是
//      "我最近动得够不够"，不是"翻某天的账"。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../data/local/database/app_database.dart';
import '../providers/weight_loss_providers.dart';
import '../widgets/exercise_picker.dart';

class ExerciseLogPage extends ConsumerWidget {
  const ExerciseLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(exerciseLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('运动记录')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('记录运动'),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceL),
            child: Text('读取失败：$e', textAlign: TextAlign.center),
          ),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.directions_run,
                title: '还没有运动记录',
                message: '记一次走路也算，消耗会累加进今日热量',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.pagePadding,
              AppTokens.spaceM,
              AppTokens.pagePadding,
              96, // 给 FAB 留位置，否则最后一条会被挡住
            ),
            children: _buildGroups(context, logs),
          );
        },
      ),
    );
  }

  /// 按天分组。返回的是扁平 children 列表（header + rows），
  /// 比嵌套 ListView 更省心，也不会出现嵌套滚动。
  static List<Widget> _buildGroups(BuildContext context, List<ExerciseLog> logs) {
    final children = <Widget>[];
    final scheme = Theme.of(context).colorScheme;

    DateTime? currentDay;
    var dayTotal = 0.0;

    for (final log in logs) {
      final day = DateTime(
        log.recordedAt.year,
        log.recordedAt.month,
        log.recordedAt.day,
      );
      if (currentDay == null || day != currentDay) {
        if (currentDay != null) {
          children.add(_DayTotal(total: dayTotal));
        }
        currentDay = day;
        dayTotal = 0;
        children.add(Padding(
          padding: const EdgeInsets.only(
            top: AppTokens.spaceM,
            bottom: AppTokens.spaceS,
          ),
          child: Text(
            _dayLabel(day),
            style: AppTokens.title.copyWith(color: scheme.onSurface),
          ),
        ));
      }
      dayTotal += log.kcal;
      children.add(_ExerciseRow(log: log));
    }
    if (currentDay != null) children.add(_DayTotal(total: dayTotal));
    return children;
  }

  static String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return '${day.month} 月 ${day.day} 日';
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile == null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('运动消耗要按体重估算，先填一下身体档案'),
            action: SnackBarAction(
              label: '去填',
              onPressed: () => context.push('/me/body-profile'),
            ),
          ),
        );
      return;
    }

    final defsAsync = ref.read(exerciseDefsProvider);
    final defs = defsAsync.valueOrNull;
    if (defs == null || defs.isEmpty) {
      // 第一次点会触发加载；加载完再点一次即可
      await ref.read(exerciseDefsProvider.future);
      if (!context.mounted) return;
      return _add(context, ref);
    }

    final pick = await showExercisePicker(
      context,
      defs: defs,
      weightKg: profile.weightKg,
    );
    if (pick == null) return;

    await ref.read(weightLossRepositoryProvider).addExercise(
          def: pick.def,
          minutes: pick.minutes,
          weightKg: profile.weightKg, // ← 记录当时的体重，不用"当前"
        );

    invalidateWeightLossChain(ref.invalidate);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('已记录 ${pick.def.name}')));
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.log});

  final ExerciseLog log;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceXs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.exerciseName, style: AppTokens.body),
                Text(
                  '${log.minutes} 分钟 · MET ${log.met.toStringAsFixed(1)} · '
                  '${log.weightKgAtTime.toStringAsFixed(1)} kg',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${log.kcal.round()} kcal',
            style: AppTokens.body.copyWith(
              color: colors.fertile,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayTotal extends StatelessWidget {
  const _DayTotal({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spaceS),
      child: Text(
        '合计 ${total.round()} kcal',
        style: AppTokens.caption.copyWith(
          color: scheme.onSurface.withAlpha(140),
        ),
      ),
    );
  }
}
