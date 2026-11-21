// lib/features/today/widgets/calorie_ring_card.dart
//
// 今日热量环（P1-3）。
//
// 三条设计约束（对应 AGENTS.md R10 / ADR-3）：
//   · 超预算用 calorieOver（橙），**绝不用红色** —— 红色只留给破坏性操作
//   · 数字必须来自 TdeeService，卡片内不做任何公式推导（避免两套算法打架）
//   · 无档案时给 EmptyState + 明确动作，不显示"0 kcal"这种看起来像算错的东西
//
// 文案原则：
//   「剩余 850 kcal」比「已摄入 650 / 预算 1500」更好读 —— 用户只想知道还能吃多少。
//   超了才反过来说「已超 120 kcal」，并且语气要平，不要"警告/超标"。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/charts/stat_ring.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../weight_loss/models/weight_loss_models.dart';
import '../../weight_loss/providers/weight_loss_providers.dart';

class CalorieRingCard extends ConsumerWidget {
  const CalorieRingCard({super.key, this.onTapEmptyAction});

  /// 空态按钮的动作（跳到身体档案页）。为 null 时按钮不显示，
  /// 便于在测试里单独渲染卡片而不依赖路由。
  final VoidCallback? onTapEmptyAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(calorieBudgetProvider);
    final energyAsync = ref.watch(todayEnergyProvider);

    // 档案还没读到 —— 用一句话占位，不闪 spinner（避免首屏抖）
    final budget = budgetAsync.valueOrNull;
    if (budgetAsync.isLoading && !budgetAsync.hasValue) {
      return const _CardShell(child: _Skeleton());
    }

    if (budget == null) {
      return _CardShell(
        child: EmptyState(
          compact: true,
          icon: Icons.local_fire_department_outlined,
          title: '还没算你的每日热量',
          message: '填完身高体重和活动量，就能知道每天能吃多少',
          actionLabel: onTapEmptyAction == null ? null : '去填身体档案',
          onAction: onTapEmptyAction,
        ),
      );
    }

    final summary = energyAsync.valueOrNull;
    // 汇总还没算出来时按 0 摄入显示，避免环形空白
    final intake = summary?.intakeKcal ?? 0;
    final burn = summary?.burnKcal ?? 0;
    final remain = summary?.remainKcal ?? budget.intakeTarget;

    return _CardShell(
      child: _RingBody(
        budget: budget,
        intake: intake,
        burn: burn,
        remain: remain,
      ),
    );
  }
}

class _RingBody extends StatelessWidget {
  const _RingBody({
    required this.budget,
    required this.intake,
    required this.burn,
    required this.remain,
  });

  final CalorieBudget budget;
  final double intake;
  final double burn;
  final double remain;

  bool get _isOver => remain < 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('今日热量', style: AppTokens.title),
            const Spacer(),
            if (burn > 0)
              _Pill(
                icon: Icons.directions_run,
                label: '运动 ${burn.round()}',
                color: colors.fertile,
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceL),
        Center(
          child: StatRing(
            budget: budget.intakeTarget,
            intake: intake,
            burn: burn,
            size: 188,
            strokeWidth: 12,
            centerChild: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  remain.abs().round().toString(),
                  style: AppTokens.display.copyWith(
                    color: _isOver ? colors.calorieOver : scheme.onSurface,
                  ),
                ),
                Text(
                  _isOver ? '已超 kcal' : '剩余 kcal',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spaceL),
        // 明细不在这里重复：预算/摄入/运动/余额由 DailySummaryCard 摊开讲。
        // 一张卡片只说一件事，避免两个地方显示同一组数字。
        // 触发安全下限时必须说明，否则用户会疑惑"为什么和我算的不一样"
        if (budget.isFloored) ...[
          const SizedBox(height: AppTokens.spaceM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield_outlined,
                size: AppTokens.spaceL,
                color: scheme.onSurface.withAlpha(120),
              ),
              const SizedBox(width: AppTokens.spaceS),
              Expanded(
                child: Text(
                  '已按安全下限调整：不低于你的基础代谢 '
                  '${budget.bmr.round()} kcal',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceS,
        vertical: AppTokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppTokens.spaceXs),
          Text(label, style: AppTokens.caption.copyWith(color: color)),
        ],
      ),
    );
  }
}

/// 首帧骨架：保持与真实卡片同高，避免内容加载完后页面跳一下。
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 220,
      child: Center(
        child: Text(
          '正在计算…',
          style: AppTokens.body.copyWith(
            color: scheme.onSurface.withAlpha(120),
          ),
        ),
      ),
    );
  }
}
