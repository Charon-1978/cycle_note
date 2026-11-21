// lib/features/period/pages/period_history_page.dart
//
// 经期历史（P5-2）。
//
// 为什么需要独立一页：日历底部的「最近周期」只列 4 段，用满一年就有十几段，
// 既看不全也没法集中纠错。原版月记有 `/period/history` 路由，这里补齐。
//
// 职责边界：
//   · 本页 = 看全 + 统计 + 删除（纠错）
//   · 补记 / 改结束日 / 逐日经量 → 仍走日历（那里有日期上下文，更适合）
//
// 统计口径与预测服务一致：只用「有 cycleLength 的段」求均值，
// 否则把进行中的那段（无长度）算进去会把平均值拉低。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../providers/period_providers.dart';
import '../services/period_prediction_service.dart';

class PeriodHistoryPage extends ConsumerWidget {
  const PeriodHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('经期历史'), centerTitle: false),
      body: cyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceL),
            child: Text('读取失败：$e', textAlign: TextAlign.center),
          ),
        ),
        data: (cycles) {
          if (cycles.isEmpty) {
            return const EmptyState(
              icon: Icons.history,
              title: '还没有经期记录',
              message: '在「今日」页记录第一次，或在日历上补记历史经期',
            );
          }

          // 倒序展示（最近的在上），与"翻历史"的心智一致
          final sorted = [...cycles]
            ..sort((a, b) => b.start.compareTo(a.start));

          // 按年分组
          final byYear = <int, List<CycleInput>>{};
          for (final c in sorted) {
            byYear.putIfAbsent(c.start.year, () => []).add(c);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pagePadding,
              vertical: AppTokens.spaceM,
            ),
            children: [
              _StatsCard(cycles: cycles),
              const SizedBox(height: AppTokens.cardGap),
              for (final year in byYear.keys) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.spaceS),
                  child: Text(
                    '$year 年 · ${byYear[year]!.length} 次',
                    style: AppTokens.title.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                for (final c in byYear[year]!)
                  _CycleRow(cycle: c, all: cycles),
                const SizedBox(height: AppTokens.spaceM),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 顶部统计：总次数、平均周期、平均经期。
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.cycles});

  final List<CycleInput> cycles;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    final lengths =
        cycles.map((c) => c.cycleLength).whereType<int>().toList();
    final periods =
        cycles.map((c) => c.resolvedPeriodLength).whereType<int>().toList();

    String avg(List<int> xs) =>
        xs.isEmpty ? '—' : (xs.reduce((a, b) => a + b) / xs.length).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceL),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppTokens.borderM,
        border: Border.all(
          color: scheme.onSurface.withAlpha(20),
          width: AppTokens.borderWidth,
        ),
      ),
      child: Row(
        children: [
          _Stat(label: '记录次数', value: '${cycles.length}', color: colors.period),
          _Stat(label: '平均周期', value: avg(lengths), unit: '天',
              color: scheme.onSurface),
          _Stat(label: '平均经期', value: avg(periods), unit: '天',
              color: scheme.onSurface),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
    this.unit,
  });

  final String label;
  final String value;
  final String? unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTokens.headline.copyWith(color: color)),
              if (unit != null) ...[
                const SizedBox(width: 2),
                Text(
                  unit!,
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.spaceXs),
          Text(
            label,
            style: AppTokens.caption.copyWith(
              color: scheme.onSurface.withAlpha(140),
            ),
          ),
        ],
      ),
    );
  }
}

/// 一行经期：区间 + 经期天数 + 周期天数 + 状态，右侧删除。
class _CycleRow extends ConsumerWidget {
  const _CycleRow({required this.cycle, required this.all});

  final CycleInput cycle;
  final List<CycleInput> all;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    final start = DateTime(cycle.start.year, cycle.start.month, cycle.start.day);
    final end = cycle.end == null
        ? null
        : DateTime(cycle.end!.year, cycle.end!.month, cycle.end!.day);
    final range = end == null
        ? '${start.month}月${start.day}日 开始'
        : '${start.month}月${start.day}日 – ${end.month}月${end.day}日';

    final periodLen = cycle.resolvedPeriodLength;
    final detail = [
      if (periodLen != null) '经期 $periodLen 天',
      if (cycle.cycleLength != null) '周期 ${cycle.cycleLength} 天',
      if (end == null) '进行中',
    ].join(' · ');

    return Dismissible(
      key: ValueKey('cycle-${start.toIso8601String()}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(context, ref, range),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTokens.spaceL),
        color: colors.danger.withAlpha(30),
        child: Icon(Icons.delete_outline, color: colors.danger),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 8,
          height: 40,
          decoration: BoxDecoration(
            color: colors.period.withAlpha(end == null ? 255 : 120),
            borderRadius: BorderRadius.circular(AppTokens.radiusS),
          ),
        ),
        title: Text(range, style: AppTokens.body.copyWith(color: scheme.onSurface)),
        subtitle: detail.isEmpty
            ? null
            : Text(
                detail,
                style: AppTokens.caption.copyWith(
                  color: scheme.onSurface.withAlpha(140),
                ),
              ),
        trailing: IconButton(
          tooltip: '删除这段',
          icon: Icon(Icons.delete_outline, color: colors.danger.withAlpha(180)),
          onPressed: () async {
            final ok = await _confirmDelete(context, ref, range);
            if (!ok || !context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('已删除 $range')));
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String range,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('删除这段经期？'),
        content: Text('$range 的记录会被删除，日历与预测将随之变化。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return false;

    final result = await ref
        .read(periodRepositoryProvider)
        .deleteHistoricalPeriod(cycle.start);
    if (!result.ok) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.error!)));
      }
      return false;
    }
    ref.invalidate(cyclesProvider);
    ref.invalidate(todayRecordProvider);
    ref.invalidate(inPeriodProvider);
    return true;
  }
}
