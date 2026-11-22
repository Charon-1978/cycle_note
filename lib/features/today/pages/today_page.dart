// lib/features/today/pages/today_page.dart
//
// 「今日」—— 唯一 daily hub。
//
// 结构（2026-11 视觉升级，参考美柚首页的信息顺序）：
//   1. 渐变头：今天几号 + 我现在处于哪个阶段（一句话结论）
//   2. 热量环（首屏唯一的大数字）
//   3. 今日明细（余额怎么来的）
//   4. 今天吃什么（四餐，点一下就能记）
//   5. 快捷入口（体重 / 运动 / 饮食 / 经期）
//   6. 洞察条（当前阶段能说什么就说什么）
//   7. 经期操作（在经期中才出现经量选择）+ 主按钮
//
// 约束（沿用原任务卡）：
//   · 不直接访问数据库，全部经 Provider/Repository（AGENTS.md §3）
//   · 颜色全部来自 context.colors（R10）
//   · 空状态用统一 EmptyState 组件

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/input/quick_action_grid.dart';
import '../../../core/widgets/input/quick_action_sheet.dart';
import '../../../core/widgets/surface/gradient_header.dart';
import '../../../core/widgets/surface/soft_card.dart';
import '../../period/data/period_tables.dart';
import '../../period/providers/period_providers.dart';
import '../../period/services/period_prediction_service.dart';
import '../../weight_loss/pages/food_log_page.dart' show recordMealFlow;
import '../../weight_loss/widgets/weight_input.dart';
import '../widgets/calorie_ring_card.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/insight_bar.dart';
import '../widgets/meal_slots_card.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyclesAsync = ref.watch(cyclesProvider);
    final phase = ref.watch(todayPhaseProvider);
    final prediction = ref.watch(predictionProvider);
    final periodDay = ref.watch(currentPeriodDayProvider);
    final todayRecord = ref.watch(todayRecordProvider).valueOrNull;

    final inPeriod = periodDay != null;

    // 「今天已经点过结束」的判定：最近一段经期的 endDate == 今天。
    // 没有它的时候，用户点完「经期结束了」页面毫无变化（数据是对的，
    // 因为今天仍算经期日），会以为没点上而反复点 —— 2026-11 走查发现。
    final now = DateTime.now();
    final today0 = DateTime(now.year, now.month, now.day);
    final endedToday = cyclesAsync.valueOrNull?.any((c) {
          if (c.end == null) return false;
          final e = c.end!;
          return DateTime(e.year, e.month, e.day) == today0;
        }) ??
        false;

    return Scaffold(
      // 渐变头自己承担顶部安全区，所以不要 AppBar，也不给 body 加 padding
      body: cyclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceL),
            child: Text('读取失败，请重试\n$e', textAlign: TextAlign.center),
          ),
        ),
        data: (cycles) => ListView(
          padding: EdgeInsets.zero,
          children: [
            GradientHeader(
              child: _Header(
                phase: phase,
                prediction: prediction,
                periodDay: periodDay,
                hasCycles: cycles.isNotEmpty,
                endedToday: endedToday,
              ),
            ),
            // 卡片上移，压住渐变下缘 —— 这是"卡片浮在头图上"的关键，
            // 上移量 = 渐变头多留的底部空间（spaceXxl - 4）。
            Transform.translate(
              offset: const Offset(0, -(AppTokens.spaceXxl - 4)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CalorieRingCard(
                      onTapEmptyAction: () => context.push('/me/body-profile'),
                    ),
                    const SizedBox(height: AppTokens.cardGap),
                    const DailySummaryCard(),
                    const SizedBox(height: AppTokens.cardGap),
                    const MealSlotsCard(),
                    const SizedBox(height: AppTokens.cardGap),
                    _QuickActions(
                      inPeriod: inPeriod,
                      endedToday: endedToday,
                      onUndoEnd: () => _undoEnd(context, ref),
                      onWeight: () => _openWeightSheet(context),
                      onPeriod: () =>
                          _onToggle(context, ref, inPeriod: inPeriod),
                    ),
                    const SizedBox(height: AppTokens.cardGap),
                    const InsightBar(),
                    const SizedBox(height: AppTokens.cardGap),
                    if (inPeriod) ...[
                      _FlowSelector(
                        // 未记录时**不预选任何一档**：预选"无"会让用户以为
                        // 自己已经记过"今天没有经量"，这是数据失真。
                        current: todayRecord?.flowLevel == null
                            ? null
                            : FlowLevel.fromValue(todayRecord!.flowLevel),
                        onSelected: (v) async {
                          await ref
                              .read(periodRepositoryProvider)
                              .updateDailyIntensity(
                                DateTime.now(),
                                flowLevel: v,
                              );
                          ref.invalidate(todayRecordProvider);
                          ref.invalidate(cyclesProvider);
                        },
                      ),
                      const SizedBox(height: AppTokens.cardGap),
                    ],
                    if (cycles.isEmpty) ...[
                      SoftCard(
                        child: const EmptyState(
                          compact: true,
                          icon: Icons.edit_calendar_outlined,
                          title: '今天还没有记录',
                          message: '记录第一次经期后，这里会显示周期与预测',
                        ),
                      ),
                      const SizedBox(height: AppTokens.cardGap),
                    ],
                    _PrimaryAction(
                      label: endedToday
                          ? '撤销结束（改回进行中）'
                          : (inPeriod ? '经期结束了' : '今天来经期了'),
                      icon: endedToday
                          ? Icons.undo
                          : (inPeriod
                              ? Icons.check_circle_outline
                              : Icons.water_drop_outlined),
                      onPressed: () => endedToday
                          ? _undoEnd(context, ref)
                          : _onToggle(context, ref, inPeriod: inPeriod),
                    ),
                    const SizedBox(height: AppTokens.spaceXxl),
                    // 给底部导航留出空间：最后一屏的内容不该被导航条盖住
                    const SizedBox(height: AppTokens.spaceXxl * 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Future<void> _undoEnd(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(periodRepositoryProvider);
    final open = await repo.openCycle();
    if (open == null) return;

    final result = await repo.clearPeriodEnd(open.startDate);
    ref.invalidate(cyclesProvider);
    ref.invalidate(inPeriodProvider);
    ref.invalidate(todayRecordProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(result.ok ? '已撤销结束，这段经期恢复为进行中' : (result.error ?? '撤销失败')),
        ),
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

/// 渐变头内容：日期 + 阶段结论 + 预测依据。
class _Header extends StatelessWidget {
  const _Header({
    required this.phase,
    required this.prediction,
    required this.periodDay,
    required this.hasCycles,
    required this.endedToday,
  });

  final CyclePhase phase;
  final PeriodPrediction? prediction;
  final int? periodDay;
  final bool hasCycles;

  /// 今天是否刚点过「经期结束了」（endDate == 今天）。
  final bool endedToday;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // 只有 1 个周期时不给"距下次经期 N 天"这种确定性表述：
    // 单周期误差可达 ±7 天，说得和"基于 6 个周期"一样肯定是在骗用户。
    final thinData = prediction != null && prediction!.basedOnCycles < 2;

    final headline = endedToday
        ? '经期已在今天结束'
        : periodDay != null
            ? '经期第 $periodDay 天'
            : prediction == null
                ? (hasCycles ? '还没到预测区间' : '开始记录你的周期')
                : thinData
                    ? '下次预计 ${_m(prediction!.periodStart)} 前后'
                    : '距下次经期 ${_daysUntil(prediction!)} 天';

    final detail = endedToday
        ? '记录已保存 · 结束日设错了可以在下面撤销'
        : prediction == null
            ? (periodDay != null
                // 只在经期中、还没有第二次记录：别提示"记录两次"，用户已经记了
                ? '这次经期还没结束，结束日可以之后补记'
                : '记录两次经期后，这里会出现下次预测')
            : thinData
                ? '只有 1 个完整周期，日期仅供参考；再记一次会准很多'
                : '预测 ${_m(prediction!.periodStart)} 开始 · '
                    '置信度 ${prediction!.confidence}% · '
                    '基于 ${prediction!.basedOnCycles} 个周期';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${now.month} 月 ${now.day} 日',
                    style: AppTokens.headline.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_weekday(now)} · ${_greeting(now)}',
                    style: AppTokens.caption.copyWith(
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
            _CircleIconButton(
              icon: Icons.calendar_month_outlined,
              onTap: () => context.go('/calendar'),
              tooltip: '打开日历',
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceXl),
        // 阶段胶囊：白底 + 语义色文字，在渐变上依然清晰
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceM,
            vertical: AppTokens.spaceXs,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(220),
            borderRadius: AppTokens.borderPill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _phaseColor(context),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTokens.spaceXs + 2),
              Text(
                phase.label,
                style: AppTokens.caption.copyWith(
                  color: _phaseColor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spaceM),
        Text(
          headline,
          style: AppTokens.display.copyWith(
            color: Colors.white,
            fontSize: 30,
            height: 1.15,
          ),
        ),
        const SizedBox(height: AppTokens.spaceXs),
        Text(
          detail,
          style: AppTokens.caption.copyWith(color: Colors.white.withAlpha(205)),
        ),
      ],
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
        return c.brand;
    }
  }

  static int _daysUntil(PeriodPrediction p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return p.periodStart.difference(today).inDays;
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withAlpha(40),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// 四个快捷入口。整块可点，比三个并排按钮更容易命中。
class _QuickActions extends ConsumerWidget {
  const _QuickActions({
    required this.inPeriod,
    required this.endedToday,
    required this.onUndoEnd,
    required this.onWeight,
    required this.onPeriod,
  });

  final bool inPeriod;
  final bool endedToday;
  final VoidCallback onUndoEnd;
  final VoidCallback onWeight;
  final VoidCallback onPeriod;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return Semantics(
      container: false,
      label: '快捷记录：体重、运动、饮食、经期',
      child: SoftCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceS,
          vertical: AppTokens.spaceS,
        ),
        child: QuickActionGrid(
          actions: [
            QuickAction(
              icon: Icons.monitor_weight_outlined,
              label: '记体重',
              onTap: onWeight,
              tint: colors.brand,
            ),
            QuickAction(
              icon: Icons.directions_run,
              label: '记运动',
              onTap: () => context.push('/me/exercise'),
              tint: colors.fertile,
            ),
            QuickAction(
              icon: Icons.restaurant_outlined,
              label: '记饮食',
              onTap: () => recordMealFlow(context, ref),
              tint: colors.calorieOver,
            ),
            QuickAction(
              icon: endedToday
                  ? Icons.undo
                  : (inPeriod
                      ? Icons.check_circle_outline
                      : Icons.water_drop_outlined),
              label: endedToday ? '撤销结束' : (inPeriod ? '结束经期' : '来经期'),
              onTap: endedToday ? onUndoEnd : onPeriod,
              tint: colors.period,
            ),
          ],
        ),
      ),
    );
  }
}

/// 经量选择。只在经期中出现。
class _FlowSelector extends StatelessWidget {
  const _FlowSelector({required this.current, required this.onSelected});

  /// null = 今天还没记经量（所有 chip 都不选中）。
  final FlowLevel? current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop_outlined, size: 16, color: colors.period),
              const SizedBox(width: AppTokens.spaceS),
              Text('今天的经量', style: AppTokens.title),
              const Spacer(),
              Text(
                '记下来能看出规律',
                style: AppTokens.caption.copyWith(
                  color: scheme.onSurface.withAlpha(110),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceM),
          Wrap(
            spacing: AppTokens.spaceS,
            runSpacing: AppTokens.spaceS,
            children: [
              for (final f in FlowLevel.values)
                ChoiceChip(
                  label: Text(f.label),
                  selected: f == current,
                  onSelected: (_) => onSelected(f.value),
                ),            ],
          ),
        ],
      ),
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
      height: AppTokens.minTouchTarget + 4,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label, style: AppTokens.title),
      ),
    );
  }
}

String _weekday(DateTime d) =>
    const ['周一', '周二', '周三', '周四', '周五', '周六', '周日'][d.weekday - 1];

String _greeting(DateTime d) {
  final h = d.hour;
  if (h < 6) return '夜深了';
  if (h < 11) return '早上好';
  if (h < 14) return '中午好';
  if (h < 18) return '下午好';
  return '晚上好';
}

String _m(DateTime d) => '${d.month} 月 ${d.day} 日';



