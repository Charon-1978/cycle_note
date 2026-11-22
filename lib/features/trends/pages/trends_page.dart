// lib/features/trends/pages/trends_page.dart
//
// 「趋势」—— 周期 / 体重 / 热量三图统一容器（P2-4）。
//
// 手册验收口径的落地：
//   · 三图共用同一个通用 TrendLineChart，切换用 TrendSegmented；
//   · 每张图都带文字摘要（TrendSummary + Semantics），读屏用户和
//     看不清图的人拿到同一份结论；
//   · 无数据 / 单点 / 极值都不崩：空序列 → EmptyState；
//     单点与极值由 TrendLineChart 内部兜底（单点画标记、范围撑 15%）；
//   · 数据口径：体重画 7 日移动平均（不是原始值），热量只画有记录的日子。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/surface/soft_card.dart';
import '../../period/providers/period_providers.dart';
import '../../weight_loss/providers/weight_loss_providers.dart';
import '../widgets/trend_line_chart.dart';
import '../widgets/trend_segmented.dart';

enum _TrendTab { cycle, weight, energy }

class TrendsPage extends ConsumerStatefulWidget {
  const TrendsPage({super.key});

  @override
  ConsumerState<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends ConsumerState<TrendsPage> {
  _TrendTab _tab = _TrendTab.cycle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('趋势'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.pagePadding,
          vertical: AppTokens.spaceM,
        ),
        children: [
          TrendSegmented<_TrendTab>(
            segments: const {
              _TrendTab.cycle: '周期',
              _TrendTab.weight: '体重',
              _TrendTab.energy: '热量',
            },
            selected: _tab,
            onChanged: (t) => setState(() => _tab = t),
          ),
          const SizedBox(height: AppTokens.cardGap),
          // 三张图共用同一张卡：切换时只有内容变，卡片外框不动，
          // 视觉上不会"跳一下"（美柚的趋势页也是这个做法）。
          SoftCard(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceL,
              AppTokens.spaceL,
              AppTokens.spaceL,
              AppTokens.spaceM,
            ),
            child: AnimatedSize(
              duration: AppTokens.durBase,
              curve: AppTokens.curve,
              alignment: Alignment.topCenter,
              child: switch (_tab) {
                _TrendTab.cycle => const _CycleTrend(),
                _TrendTab.weight => const _WeightTrend(),
                _TrendTab.energy => const _EnergyTrend(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _mmdd(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 周期长度趋势：每个已关闭周期之间的间隔天数。
class _CycleTrend extends ConsumerWidget {
  const _CycleTrend();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);
    return cyclesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('加载失败：$e'),
      data: (cycles) {
        final lengths = cycles
            .where((c) => c.cycleLength != null && c.cycleLength! > 0)
            .toList();
        if (lengths.isEmpty) {
          return const EmptyState(
            icon: Icons.event_repeat,
            title: '周期数据还不够',
            message: '至少记录两个周期的开始日期，才能算出周期长度趋势',
          );
        }

        final data = [
          for (final c in lengths) TrendDatum(value: c.cycleLength!.toDouble(), label: _mmdd(c.start)),
        ];
        final values = data.map((d) => d.value).toList();
        final avg = values.fold(0.0, (s, v) => s + v) / values.length;
        final summary = lengths.length == 1
            ? '只有 1 个完整周期（${values[0].round()} 天），记录下一个开始日即可出现趋势线'
            : '共 ${lengths.length} 个完整周期，平均 ${avg.toStringAsFixed(1)} 天，'
                '最长 ${values.reduce((a, b) => a > b ? a : b).round()} 天，'
                '最短 ${values.reduce((a, b) => a < b ? a : b).round()} 天';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrendLineChart(
              data: data,
              unit: '天',
              semanticName: '周期长度趋势图',
            ),
            const SizedBox(height: AppTokens.spaceS),
            TrendSummary(text: summary),
          ],
        );
      },
    );
  }
}

/// 体重趋势：7 日移动平均（与体重页同一口径，原始值太抖）。
class _WeightTrend extends ConsumerWidget {
  const _WeightTrend();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(weightTrendProvider);
    return trendAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('加载失败：$e'),
      data: (points) {
        if (points.isEmpty) {
          return const EmptyState(
            icon: Icons.monitor_weight_outlined,
            title: '还没有体重记录',
            message: '记下第一次体重，趋势图从这里开始',
          );
        }

        final data = [
          for (final p in points) TrendDatum(value: p.trend, label: _mmdd(p.date)),
        ];
        final latest = points.last.trend;
        final diff = points.last.trend - points.first.trend;
        final dir = diff.abs() < 0.05 ? '持平' : (diff < 0 ? '下降' : '上升');
        final summary = points.length == 1
            ? '最新体重 ${latest.toStringAsFixed(1)} kg，再记录几天就能看到趋势线'
            : '最新 ${latest.toStringAsFixed(1)} kg，'
                '期间$dir${diff.abs().toStringAsFixed(1)} kg（7 日移动平均口径）';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrendLineChart(
              data: data,
              unit: 'kg',
              semanticName: '体重趋势图',
              valueFormatter: (v) => v.toStringAsFixed(1),
            ),
            const SizedBox(height: AppTokens.spaceS),
            TrendSummary(text: summary),
          ],
        );
      },
    );
  }
}

/// 热量趋势：每日摄入（只画有记录的日子）。
class _EnergyTrend extends ConsumerWidget {
  const _EnergyTrend();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(dailyEnergySeriesProvider);
    return seriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('加载失败：$e'),
      data: (series) {
        if (series.isEmpty) {
          return const EmptyState(
            icon: Icons.local_fire_department_outlined,
            title: '还没有饮食或运动记录',
            message: '记一次饮食或运动，这里会开始画每日热量',
          );
        }

        final data = [
          for (final p in series)
            TrendDatum(value: p.intakeKcal, label: _mmdd(p.date)),
        ];
        final avg = data.map((d) => d.value).fold(0.0, (s, v) => s + v) /
            data.length;
        final budgetAsync = ref.watch(calorieBudgetProvider);
        final budget = budgetAsync.valueOrNull?.intakeTarget;
        final summary = budget == null
            ? '有记录的 ${data.length} 天平均摄入 ${avg.round()} kcal'
            : '有记录的 ${data.length} 天平均摄入 ${avg.round()} kcal，'
                '当前预算 ${budget.round()} kcal';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TrendLineChart(
              data: data,
              unit: 'kcal',
              semanticName: '每日摄入热量趋势图',
            ),
            const SizedBox(height: AppTokens.spaceS),
            TrendSummary(text: summary),
          ],
        );
      },
    );
  }
}
