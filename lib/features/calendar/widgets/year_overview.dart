// lib/features/calendar/widgets/year_overview.dart
//
// 年视图：12 个月缩略格子（计划书 §4.2 的「年视图」）。
//
// 用途：不是用来逐日记录的，而是回答"这一年我来过几次、规律不规律"。
// 所以每个格子只画**状态色点**，不画数字；点某个月进月视图再看细节。
//
// 纯展示组件：阶段判定由 phaseOfDay 回调注入（与 MonthGrid 同一约定），
// 组件本身不碰 Provider / 数据库（AGENTS.md §3）。

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../period/services/period_prediction_service.dart';
import '../utils/month_matrix.dart';

class YearOverview extends StatelessWidget {
  const YearOverview({
    super.key,
    required this.year,
    required this.phaseOfDay,
    this.isRecorded,
    this.onTapMonth,
    this.today,
  });

  final int year;
  final CyclePhase Function(DateTime day) phaseOfDay;

  /// 经期是否已记录（false = 预测）。用于把"预测"画淡一档。
  final bool Function(DateTime day)? isRecorded;

  /// 点某个月（回传该月 1 号）。
  final ValueChanged<DateTime>? onTapMonth;

  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = today ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.cardGap),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: AppTokens.spaceM),
                  Expanded(
                    child: _MiniMonth(
                      month: row * 3 + col + 1,
                      year: year,
                      phaseOfDay: phaseOfDay,
                      isRecorded: isRecorded,
                      isCurrentMonth: year == now.year && row * 3 + col + 1 == now.month,
                      onTap: onTapMonth,
                    ),
                  ),
                ],
              ],
            ),
          ),
        Row(
          children: [
            _LegendDot(color: context.colors.period, label: '经期'),
            const SizedBox(width: AppTokens.spaceM),
            _LegendDot(
              color: context.colors.period,
              label: '预测',
              hollow: true,
            ),
            const SizedBox(width: AppTokens.spaceM),
            _LegendDot(color: context.colors.fertile, label: '易孕'),
            const SizedBox(width: AppTokens.spaceM),
            _LegendDot(color: context.colors.ovulation, label: '排卵'),
            const Spacer(),
            Text(
              '$year 年',
              style: AppTokens.caption.copyWith(
                color: scheme.onSurface.withAlpha(140),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.year,
    required this.month,
    required this.phaseOfDay,
    required this.isCurrentMonth,
    this.isRecorded,
    this.onTap,
  });

  final int year;
  final int month;
  final CyclePhase Function(DateTime day) phaseOfDay;

  /// 可选：区分"已记录"与"预测"。为空时按已记录处理。
  final bool Function(DateTime day)? isRecorded;

  final bool isCurrentMonth;
  final ValueChanged<DateTime>? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final matrix = buildMonthMatrix(year, month);

    return InkWell(
      onTap: onTap == null ? null : () => onTap!(DateTime(year, month)),
      borderRadius: AppTokens.borderM,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceS,
          vertical: AppTokens.spaceS,
        ),
        decoration: BoxDecoration(
          color: isCurrentMonth ? colors.brandSoft : Colors.transparent,
          borderRadius: AppTokens.borderM,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$month 月',
              style: AppTokens.caption.copyWith(
                color: isCurrentMonth ? colors.brand : scheme.onSurface.withAlpha(170),
                fontWeight: isCurrentMonth ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTokens.spaceXs),
            for (final week in matrix)
              Row(
                children: [
                  for (final day in week)
                    Expanded(
                      child: SizedBox(
                        height: 10,
                        child: Center(
                          child: day == null
                              ? const SizedBox.shrink()
                              : _Dot(
                                  phase: phaseOfDay(day),
                                  recorded: isRecorded?.call(day) ?? true,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.phase, this.recorded = true});

  final CyclePhase phase;

  /// 经期是否已记录：false（预测）画成半透明，避免和真实记录混淆。
  final bool recorded;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    final bool predictedOnly = phase == CyclePhase.menstrual && !recorded;
    final Color? color = switch (phase) {
      CyclePhase.menstrual =>
        predictedOnly ? colors.period.withAlpha(90) : colors.period,
      CyclePhase.ovulation => colors.ovulation,
      CyclePhase.fertile => colors.fertile,
      CyclePhase.normal => null,
    };

    // 6px：5px 在这个密度下几乎看不见，6px 才够"远看有颜色"。
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color ?? scheme.onSurface.withAlpha(26),
        shape: BoxShape.circle,
        border: predictedOnly
            ? Border.all(color: colors.period, width: 1)
            : null,
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    this.hollow = false,
  });

  final Color color;
  final String label;

  /// 空心 = 预测（与月视图的"预测经期"描边同一语义）。
  final bool hollow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: hollow ? Colors.transparent : color,
            shape: BoxShape.circle,
            border: hollow ? Border.all(color: color, width: 1) : null,
          ),
        ),
        const SizedBox(width: AppTokens.spaceXs),
        Text(
          label,
          style: AppTokens.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(140),
          ),
        ),
      ],
    );
  }
}




