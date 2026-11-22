// lib/features/today/widgets/insight_bar.dart
//
// 「今日洞察」一条（视觉升级新增，对应计划书 §4.2 的"洞察条"）。
//
// 原则：
//   · 只说**当下这条数据能支撑的话**。没有数据就说"记一笔才有洞察"，
//     不编造健康建议（AGENTS.md §9 数据安全红线的同源要求：不编造）。
//   · 文案随阶段变化，优先级：经期 > 排卵 > 易孕 > 热量余额 > 兜底。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../period/providers/period_providers.dart';
import '../../period/services/period_prediction_service.dart';
import '../../weight_loss/providers/weight_loss_providers.dart';

class InsightBar extends ConsumerWidget {
  const InsightBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(todayPhaseProvider);
    final periodDay = ref.watch(currentPeriodDayProvider);
    final summary = ref.watch(todayEnergyProvider).valueOrNull;
    final budget = ref.watch(calorieBudgetProvider).valueOrNull;

    final insight = _pick(
      phase: phase,
      periodDay: periodDay,
      remain: summary?.remainKcal,
      hasBudget: budget != null,
    );

    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceL,
        vertical: AppTokens.spaceM,
      ),
      decoration: BoxDecoration(
        color: colors.brandSoft,
        borderRadius: AppTokens.borderL,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            insight.icon,
            size: 18,
            color: insight.colorOf(colors) ?? colors.brand,
          ),
          const SizedBox(width: AppTokens.spaceS),
          Expanded(
            child: Text(
              insight.text,
              style: AppTokens.caption.copyWith(
                color: scheme.onSurface.withAlpha(190),
                height: 18 / 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static _Insight _pick({
    required CyclePhase phase,
    required int? periodDay,
    required double? remain,
    required bool hasBudget,
  }) {
    if (periodDay != null) {
      return _Insight(
        icon: Icons.water_drop_outlined,
        text: '经期第 $periodDay 天：今天可以多吃一点含铁的东西'
            '（红肉、菠菜、豆类），别硬扛疲倦。',
        tone: _Tone.period,
      );
    }
    if (phase == CyclePhase.ovulation) {
      return const _Insight(
        icon: Icons.circle_outlined,
        text: '排卵日附近：这两天基础体温会略高，属正常波动。',
        tone: _Tone.ovulation,
      );
    }
    if (phase == CyclePhase.fertile) {
      return const _Insight(
        icon: Icons.spa_outlined,
        text: '易孕期：想吃东西、食欲偏高是激素在作怪，不用责怪自己。',
        tone: _Tone.fertile,
      );
    }
    if (hasBudget && remain != null) {
      if (remain < 0) {
        return _Insight(
          icon: Icons.trending_flat,
          text: '今天超了 ${remain.abs().round()} kcal：'
              '一天的超额不会毁掉进度，明天回到预算内就行。',
          tone: _Tone.over,
        );
      }
      return _Insight(
        icon: Icons.local_fire_department_outlined,
        text: '今天还能吃 ${remain.round()} kcal，'
            '大约是一份主食 + 一份蛋白的量。',
        tone: _Tone.brand,
      );
    }
    return const _Insight(
      icon: Icons.auto_graph,
      text: '记一次经期或体重，这里会出现与你当天状态相关的提示。',
      tone: _Tone.brand,
    );
  }
}

enum _Tone { brand, period, fertile, ovulation, over }

class _Insight {
  const _Insight({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final _Tone tone;

  Color? colorOf(AppColors c) {
    switch (tone) {
      case _Tone.brand:
        return c.brand;
      case _Tone.period:
        return c.period;
      case _Tone.fertile:
        return c.fertile;
      case _Tone.ovulation:
        return c.ovulation;
      case _Tone.over:
        return c.calorieOver;
    }
  }
}
