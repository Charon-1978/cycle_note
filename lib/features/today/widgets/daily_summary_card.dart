// lib/features/today/widgets/daily_summary_card.dart
//
// 今日热量明细（P1-6）。
//
// 和热量环的分工：
//   · 环 = 一眼看还剩多少（hero，不放明细）
//   · 本卡 = 把「余额是怎么来的」摊开：摄入 − 运动 + 预算 → 余额
//
// 硬约束（手册 P1-6 禁止项）：
//   ❌ 余额**必须**用 `DailyEnergySummary.remainKcal`，widget 内不得重写公式。
//      否则将来改公式时，环和卡片会各显示一个数，谁对说不清。
//   ❌ 不在本卡做饮食记录（P2-3）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../weight_loss/data/weight_loss_repository.dart';
import '../../weight_loss/providers/weight_loss_providers.dart';

class DailySummaryCard extends ConsumerWidget {
  const DailySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todayEnergyProvider).valueOrNull;
    if (summary == null) return const SizedBox.shrink();

    return _Body(summary: summary);
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.summary});

  final DailyEnergySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    final remain = summary.remainKcal;
    final isOver = remain < 0;
    final remainColor = isOver ? colors.calorieOver : scheme.onSurface;

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
          Text('今日明细', style: AppTokens.title),
          const SizedBox(height: AppTokens.spaceM),

          // 一行等式：预算 − 摄入 + 运动 = 余额
          // 用 Wrap 而不是 Row：小屏幕上窄，宁可换行也不截断数字
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTokens.spaceS,
            runSpacing: AppTokens.spaceXs,
            children: [
              _Term(label: '预算', value: summary.budgetKcal.round()),
              const _Op('−'),
              _Term(label: '摄入', value: summary.intakeKcal.round()),
              const _Op('+'),
              _Term(label: '运动', value: summary.burnKcal.round()),
              const _Op('='),
              _Term(
                label: '余额',
                value: remain.abs().round(),
                strong: true,
                prefix: isOver ? '−' : '',
                color: remainColor,
              ),
            ],
          ),

          if (isOver) ...[
            const SizedBox(height: AppTokens.spaceM),
            Text(
              '今天超了 ${remain.abs().round()} kcal。一天的超额不会毁掉进度，'
              '明天回到预算内就行。',
              style: AppTokens.caption.copyWith(
                color: scheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Term extends StatelessWidget {
  const _Term({
    required this.label,
    required this.value,
    this.strong = false,
    this.prefix = '',
    this.color,
  });

  final String label;
  final int value;
  final bool strong;
  final String prefix;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$prefix$value',
          style: (strong ? AppTokens.headline : AppTokens.title)
              .copyWith(color: color ?? scheme.onSurface),
        ),
        Text(
          label,
          style: AppTokens.caption.copyWith(
            color: scheme.onSurface.withAlpha(120),
          ),
        ),
      ],
    );
  }
}

class _Op extends StatelessWidget {
  const _Op(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spaceL),
      child: Text(
        text,
        style: AppTokens.title.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
        ),
      ),
    );
  }
}
