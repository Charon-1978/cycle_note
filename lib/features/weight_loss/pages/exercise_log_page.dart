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
import '../../../core/widgets/surface/soft_card.dart';
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

  /// 按天分组。每天一张卡：卡内是该天的若干条 + 当日合计。
  ///
  /// 2026-11 视觉升级：原来是"扁平行 + 无边框"，一天有 3 条时看不出
  /// 哪些属于同一天；改成按天成卡后，"今天练了几次、一共多少"一眼可得。
  static List<Widget> _buildGroups(BuildContext context, List<ExerciseLog> logs) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    // 先分组（保持 logs 原有顺序：仓库已按时间倒序返回）
    final groups = <DateTime, List<ExerciseLog>>{};
    for (final log in logs) {
      final day = DateTime(
        log.recordedAt.year,
        log.recordedAt.month,
        log.recordedAt.day,
      );
      groups.putIfAbsent(day, () => <ExerciseLog>[]).add(log);
    }

    final children = <Widget>[];
    groups.forEach((day, items) {
      final total = items.fold<double>(0, (s, l) => s + l.kcal);
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppTokens.cardGap),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.spaceS),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colors.fertile,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceS),
                    Text(
                      _dayLabel(day),
                      style: AppTokens.title.copyWith(color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
              SoftCard(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.spaceL,
                  AppTokens.spaceS,
                  AppTokens.spaceL,
                  AppTokens.spaceS,
                ),
                child: Column(
                  children: [
                    for (final log in items) _ExerciseRow(log: log),
                    Divider(
                      height: 1,
                      color: scheme.onSurface.withAlpha(12),
                    ),
                    _DayTotal(total: total),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
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
          const SizedBox(width: AppTokens.spaceXs),
          _DeleteButton(logId: log.id, name: log.exerciseName),
        ],
      ),
    );
  }
}

/// 删除一条运动记录。破坏性操作 → 红色 + 二次确认（ADR-3 的唯一豁免场景）。
class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.logId, required this.name});

  final int logId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.close, size: 18, color: colors.danger),
      tooltip: '删除',
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除这条运动？'),
            content: Text('「$name」将从今日消耗中移除，热量会重新计算。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('删除', style: TextStyle(color: colors.danger)),
              ),
            ],
          ),
        );
        if (ok != true) return;
        await ref.read(weightLossRepositoryProvider).deleteExercise(logId);
        invalidateWeightLossChain(ref.invalidate);
      },
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

