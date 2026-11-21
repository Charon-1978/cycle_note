// lib/features/weight_loss/pages/weight_log_page.dart
//
// 体重趋势（P1-4）。
//
// 页面只回答三个问题：
//   1) 我现在多重（最新一次 + 7 日平均，两者不同：前者有波动、后者是真实趋势）
//   2) 离目标还有多远
//   3) 最近都记了什么
//
// 验收对应的实现约束：
//   · "一天记多条取当日最后一条" 已在 repository.weightTrend 里实现（顺序覆盖），
//     这里不重复实现，也不画第二套移动平均。
//   · 0 / 1 / 2 条数据都不崩：0 条走 EmptyState，1 条只画点不画线（chart 内处理）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/input/quick_action_sheet.dart';
import '../data/weight_loss_repository.dart' show WeightPoint;
import '../providers/weight_loss_providers.dart';
import '../widgets/weight_input.dart';
import '../widgets/weight_trend_chart.dart';

class WeightLogPage extends ConsumerWidget {
  const WeightLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);
    final latest = ref.watch(latestWeightProvider).valueOrNull;
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final target = profile?.resolvedTargetWeight;

    return Scaffold(
      appBar: AppBar(title: const Text('体重趋势')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _record(context),
        icon: const Icon(Icons.monitor_weight_outlined),
        label: const Text('记体重'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pagePadding,
          AppTokens.spaceM,
          AppTokens.pagePadding,
          96, // 给 FAB 留位置
        ),
        children: [
          _SummaryCard(latest: latest, target: target),
          const SizedBox(height: AppTokens.cardGap),
          trendAsync.when(
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppTokens.spaceL),
              child: Text('读取失败：$e', textAlign: TextAlign.center),
            ),
            data: (points) => points.isEmpty
                ? const EmptyState(
                    icon: Icons.show_chart,
                    title: '记一次体重，开始看趋势',
                    message: '体重每天波动 1 kg 内都正常，看 7 天平均才有意义',
                  )
                : _ChartCard(
                    points: points,
                    targetWeightKg: target,
                  ),
          ),
          const SizedBox(height: AppTokens.cardGap),
          const _RecentList(),
        ],
      ),
    );
  }

  void _record(BuildContext context) {
    showQuickActionSheet(
      context,
      title: '记录体重',
      tabs: [
        QuickActionTab(
          label: '体重',
          icon: Icons.monitor_weight_outlined,
          builder: (_) => const WeightQuickInput(),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.latest, required this.target});

  final double? latest;
  final double? target;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final latest = this.latest;
    final target = this.target;

    // 差值用中性灰/绿表达，**不用红**（ADR-3：体重上升不是"错误"）
    final diff = (latest != null && target != null) ? latest - target : null;
    final diffText = diff == null
        ? null
        : (diff.abs() < 0.05
            ? '已达标'
            : (diff > 0 ? '还需减 ${diff.toStringAsFixed(1)} kg' : '低于目标 ${diff.abs().toStringAsFixed(1)} kg'));
    final diffColor = diff == null
        ? scheme.onSurfaceVariant
        : (diff > 0.05 ? colors.weightUp : colors.weightDown);

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceL),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppTokens.borderL,
        border: Border.all(
          color: scheme.onSurface.withAlpha(20),
          width: AppTokens.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前体重', style: AppTokens.label.copyWith(
                  color: scheme.onSurface.withAlpha(140),
                )),
                const SizedBox(height: AppTokens.spaceXs),
                latest == null
                    ? Text('未记录', style: AppTokens.headline.copyWith(
                        color: scheme.onSurface.withAlpha(120),
                      ))
                    : Text(
                        latest.toStringAsFixed(1),
                        style: AppTokens.display,
                      ),
              ],
            ),
          ),
          if (diffText != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(diffText, style: AppTokens.body.copyWith(color: diffColor)),
                const SizedBox(height: AppTokens.spaceXs),
                Text(
                  '目标 ${target?.toStringAsFixed(1)} kg',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.points, required this.targetWeightKg});

  final List<WeightPoint> points;
  final double? targetWeightKg;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceL),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppTokens.borderL,
        border: Border.all(
          color: scheme.onSurface.withAlpha(20),
          width: AppTokens.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('近 30 天', style: AppTokens.title),
              const Spacer(),
              _Legend(dot: scheme.primary, label: '7 日平均'),
              const SizedBox(width: AppTokens.spaceM),
              _Legend(
                dot: scheme.onSurface.withAlpha(89),
                label: '每日',
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceM),
          WeightTrendChart(
            points: points,
            targetWeightKg: targetWeightKg,
          ),
          if (targetWeightKg != null) ...[
            const SizedBox(height: AppTokens.spaceS),
            Text(
              '虚线为目标体重 ${targetWeightKg!.toStringAsFixed(1)} kg',
              style: AppTokens.caption.copyWith(
                color: scheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.dot, required this.label});

  final Color dot;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTokens.spaceXs),
        Text(
          label,
          style: AppTokens.caption.copyWith(
            color: scheme.onSurface.withAlpha(140),
          ),
        ),
      ],
    );
  }
}

class _RecentList extends ConsumerWidget {
  const _RecentList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);
    final points = trendAsync.valueOrNull ?? const [];
    final scheme = Theme.of(context).colorScheme;

    if (points.isEmpty) return const SizedBox.shrink();

    final shown = points.reversed.take(10).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('最近记录', style: AppTokens.title),
        const SizedBox(height: AppTokens.spaceS),
        for (final p in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceXs),
            child: Row(
              children: [
                Text(
                  '${p.date.month} 月 ${p.date.day} 日',
                  style: AppTokens.body.copyWith(
                    color: scheme.onSurface.withAlpha(160),
                  ),
                ),
                const Spacer(),
                Text(
                  p.raw.toStringAsFixed(1),
                  style: AppTokens.body.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: AppTokens.spaceXs),
                Text(
                  'kg',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
