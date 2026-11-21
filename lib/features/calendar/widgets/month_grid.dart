// lib/features/calendar/widgets/month_grid.dart
//
// 月历网格。**纯展示组件**：阶段判定通过 phaseOfDay 回调注入，
// 组件本身不碰 Provider / 数据库（AGENTS.md §3）。
//
// 为什么这样切：日历的着色规则会随产品演进（二期可能要显示体温、性生活标记），
// 把"哪些天是什么状态"留在页面层，组件只负责"怎么画"，改起来互不影响。

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../period/services/period_prediction_service.dart';
import '../utils/month_matrix.dart';

class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required this.month,
    required this.phaseOfDay,
    this.onTapDay,
    this.today,
    this.cellHeight = 44,
  });

  /// 该月任意一天（取年月）。
  final DateTime month;

  /// 某天处于哪个阶段。
  final CyclePhase Function(DateTime day) phaseOfDay;

  final ValueChanged<DateTime>? onTapDay;

  /// 今天（可注入，便于测试与截图）。
  final DateTime? today;

  final double cellHeight;

  static const List<String> _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final matrix = buildMonthMatrix(month.year, month.month);
    final now = today ?? DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 星期表头
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: AppTokens.caption.copyWith(
                      color: scheme.onSurface.withAlpha(120),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceXs),
        // 6 行日期
        for (final row in matrix)
          Row(
            children: [
              for (final day in row)
                Expanded(
                  child: SizedBox(
                    height: cellHeight,
                    child: day == null
                        ? const SizedBox.shrink()
                        : _DayCell(
                            day: day,
                            phase: phaseOfDay(day),
                            isToday: isSameDay(day, now),
                            onTap: onTapDay,
                          ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.phase,
    required this.isToday,
    this.onTap,
  });

  final DateTime day;
  final CyclePhase phase;
  final bool isToday;
  final ValueChanged<DateTime>? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    final (Color background, Color foreground) = switch (phase) {
      CyclePhase.menstrual => (colors.period.withAlpha(38), colors.period),
      CyclePhase.ovulation => (colors.ovulation.withAlpha(46), colors.ovulation),
      CyclePhase.fertile => (colors.fertile.withAlpha(28), colors.fertile),
      CyclePhase.normal => (Colors.transparent, scheme.onSurface.withAlpha(200)),
    };

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radiusS),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
          onTap: onTap == null ? null : () => onTap!(day),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTokens.radiusS),
              border: isToday
                  ? Border.all(color: scheme.primary, width: 1.5)
                  : null,
            ),
            child: Text(
              '${day.day}',
              style: AppTokens.label.copyWith(
                color: foreground,
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 图例。与 MonthGrid 配套使用，避免用户看不懂颜色。
class PhaseLegend extends StatelessWidget {
  const PhaseLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppTokens.spaceL,
      runSpacing: AppTokens.spaceS,
      children: [
        _item(context, colors.period, '经期'),
        _item(context, colors.fertile, '易孕期'),
        _item(context, colors.ovulation, '排卵日'),
        _item(context, scheme.onSurface.withAlpha(120), '普通日', outlined: true),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    Color color,
    String label, {
    bool outlined = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color.withAlpha(38),
            border: outlined ? Border.all(color: color, width: 1) : null,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppTokens.spaceXs),
        Text(
          label,
          style: AppTokens.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ],
    );
  }
}
