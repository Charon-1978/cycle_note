// lib/features/today/pages/today_page.dart
//
// 「今日」—— 唯一 daily hub。
//
// 本页是经期模块的第一个完整闭环（任务卡 P1-7）：
//   看阶段 → 点「经期开始/结束」→ 落库 → 立即刷新 → 预测更新
//
// 设计约束：
//   · 不直接访问数据库，全部经 Provider/Repository（AGENTS.md §3）
//   · 颜色全部来自 context.colors（R10）
//   · 空状态用统一 EmptyState 组件

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/input/quick_action_sheet.dart';
import '../../period/data/period_tables.dart';
import '../../period/providers/period_providers.dart';
import '../../period/services/period_prediction_service.dart';
import '../widgets/calorie_ring_card.dart';
import '../widgets/daily_summary_card.dart';
import '../../weight_loss/pages/food_log_page.dart' show recordMealFlow;
import '../../weight_loss/widgets/weight_input.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final prediction = ref.watch(predictionProvider);
    final phase = ref.watch(todayPhaseProvider);
    final periodDay = ref.watch(currentPeriodDayProvider);
    final todayRecord = ref.watch(todayRecordProvider).valueOrNull;

    final inPeriod = periodDay != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(DateTime.now())),
        centerTitle: false,
      ),
      body: cyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceL),
            child: Text('读取失败，请重试\n$e', textAlign: TextAlign.center),
          ),
        ),
        data: (cycles) {
          if (cycles.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.pagePadding,
                vertical: AppTokens.spaceM,
              ),
              children: [
                _ringCard(context),
                const SizedBox(height: AppTokens.cardGap),
                const DailySummaryCard(),
                const SizedBox(height: AppTokens.cardGap),
              _QuickRecordRow(onRecordWeight: () => _openWeightSheet(context)),
              const SizedBox(height: AppTokens.cardGap),                const EmptyState(
                  icon: Icons.edit_calendar_outlined,
                  title: '今天还没有记录',
                  message: '记录第一次经期后，这里会显示周期与预测',
                ),
                const SizedBox(height: AppTokens.spaceL),
                _PrimaryAction(
                  label: '今天来经期了',
                  icon: Icons.water_drop_outlined,
                  onPressed: () => _onToggle(context, ref, inPeriod: false),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pagePadding,
              vertical: AppTokens.spaceM,
            ),
            children: [
              _ringCard(context),
              const SizedBox(height: AppTokens.cardGap),
              const DailySummaryCard(),
              const SizedBox(height: AppTokens.cardGap),
              _QuickRecordRow(onRecordWeight: () => _openWeightSheet(context)),
              const SizedBox(height: AppTokens.cardGap),              _PhaseCard(
                phase: phase,
                prediction: prediction,
                periodDay: periodDay,
              ),
              const SizedBox(height: AppTokens.cardGap),
              if (inPeriod) ...[
                _FlowSelector(
                  current: FlowLevel.fromValue(todayRecord?.flowLevel),
                  onSelected: (v) async {
                    await ref
                        .read(periodRepositoryProvider)
                        .updateDailyIntensity(DateTime.now(), flowLevel: v);
                    ref.invalidate(todayRecordProvider);
                    ref.invalidate(cyclesProvider);
                  },
                ),
                const SizedBox(height: AppTokens.cardGap),
              ],
              _PrimaryAction(
                label: inPeriod ? '经期结束了' : '今天来经期了',
                icon: inPeriod
                    ? Icons.check_circle_outline
                    : Icons.water_drop_outlined,
                onPressed: () => _onToggle(context, ref, inPeriod: inPeriod),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 热量环。空态按钮直接推到身体档案页。
  Widget _ringCard(BuildContext context) => CalorieRingCard(
        onTapEmptyAction: () => context.push('/me/body-profile'),
      );

  /// 快捷记录：体重走弹层，运动进记录页。
  /// 放在今日页是因为"记一笔"是 daily hub 的高频动作，
  /// 但不该为此多占一张卡片，一行两个按钮刚好。
  void _openWeightSheet(BuildContext context) {
    showQuickActionSheet(
      context,
      title: '记录',
      initialIndex: 0,
      tabs: [
        QuickActionTab(
          label: '体重',
          icon: Icons.monitor_weight_outlined,
          builder: (_) => const WeightQuickInput(),
        ),
      ],
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    WidgetRef ref, {
    required bool inPeriod,
  }) async {
    final repo = ref.read(periodRepositoryProvider);
    final now = DateTime.now();

    String message;
    if (inPeriod) {
      final ok = await repo.endPeriod(now);
      message = ok ? '已记录经期结束' : '当前没有进行中的经期';
    } else {
      final started = await repo.startPeriod(now);
      message = started != null ? '已记录经期开始' : '今天已经记录过经期了';
    }

    // 让所有依赖 cycles 的 Provider 重算
    ref.invalidate(cyclesProvider);
    ref.invalidate(inPeriodProvider);
    ref.invalidate(todayRecordProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// 阶段卡片：一句话说清"今天是什么日子"。
class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phase,
    required this.prediction,
    required this.periodDay,
  });

  final CyclePhase phase;
  final PeriodPrediction? prediction;
  final int? periodDay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _phaseColor(context);

    final headline = periodDay != null
        ? '经期第 $periodDay 天'
        : prediction == null
            ? '数据还不够'
            : '距下次经期 ${_daysUntil(prediction!)} 天';

    final subtitle = prediction == null
        ? '再记录一个周期，就能算出下次时间'
        : '预测 ${_formatDate(prediction!.periodStart)} 开始'
            ' · 置信度 ${prediction!.confidence}%';

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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTokens.spaceS),
              Text(
                phase.label,
                style: AppTokens.label.copyWith(color: accent),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceM),
          Text(
            headline,
            style: AppTokens.display.copyWith(color: scheme.onSurface),
          ),
          const SizedBox(height: AppTokens.spaceXs),
          Text(
            subtitle,
            style: AppTokens.body.copyWith(
              color: scheme.onSurface.withAlpha(153),
            ),
          ),
          if (prediction != null) ...[
            const SizedBox(height: AppTokens.spaceM),
            Text(
              '基于 ${prediction!.basedOnCycles} 个周期 · '
              '平均 ${prediction!.cycleLength} 天',
              style: AppTokens.caption.copyWith(
                color: scheme.onSurface.withAlpha(120),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _phaseColor(BuildContext context) {
    final c = context.colors;
    switch (phase) {
      case CyclePhase.menstrual:
        return c.period;
      case CyclePhase.ovulation:
        return c.ovulation;
      case CyclePhase.fertile:
        return c.fertile;
      case CyclePhase.normal:
        return Theme.of(context).colorScheme.onSurface.withAlpha(120);
    }
  }

  static int _daysUntil(PeriodPrediction p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return p.periodStart.difference(today).inDays;
  }
}

/// 经量选择。只在经期中出现。
class _FlowSelector extends StatelessWidget {
  const _FlowSelector({required this.current, required this.onSelected});

  final FlowLevel current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今天的经量',
          style:
              AppTokens.label.copyWith(color: scheme.onSurface.withAlpha(153)),
        ),
        const SizedBox(height: AppTokens.spaceS),
        Wrap(
          spacing: AppTokens.spaceS,
          children: [
            for (final f in FlowLevel.values)
              ChoiceChip(
                label: Text(f.label),
                selected: f == current,
                onSelected: (_) => onSelected(f.value),
              ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTokens.minTouchTarget,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: AppTokens.title),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime d) => '${d.month} 月 ${d.day} 日';

/// 今日页的快捷记录行。
class _QuickRecordRow extends ConsumerWidget {
  const _QuickRecordRow({this.onRecordWeight});

  /// 弹层入口由 TodayPage 注入，保证"记体重"全 App 只有一个开法。
  final VoidCallback? onRecordWeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRecordWeight,
            icon: const Icon(Icons.monitor_weight_outlined, size: 18),
            label: const Text('记体重'),
          ),
        ),
        const SizedBox(width: AppTokens.spaceM),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/me/exercise'),
            icon: const Icon(Icons.directions_run, size: 18),
            label: const Text('记运动'),
          ),
        ),
        const SizedBox(width: AppTokens.spaceM),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => recordMealFlow(context, ref),
            icon: const Icon(Icons.restaurant_outlined, size: 18),
            label: const Text('记饮食'),
          ),
        ),
      ],
    );
  }
}
