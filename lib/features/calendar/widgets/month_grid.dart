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
    this.isRecorded,
    this.onTapDay,
    this.isEnabled,
    this.selected,
    this.today,
    this.cellHeight = 44,
  });

  /// 该月任意一天（取年月）。
  final DateTime month;

  /// 某天处于哪个阶段。
  final CyclePhase Function(DateTime day) phaseOfDay;

  /// 该天的经期是否**已记录**（false = 只是预测）。
  ///
  /// 为什么需要它：`phaseOf` 对"已记录经期"和"预测经期"都返回 menstrual，
  /// 但产品上这两者必须能区分（计划书 §4.3.3：预测值必须视觉可区分）。
  /// 传 null 时一律按"已记录"画。
  final bool Function(DateTime day)? isRecorded;

  final ValueChanged<DateTime>? onTapDay;

  /// 该天是否可点。返回 false 时格子变淡且不可点（不参与命中测试）。
  ///
  /// 典型用途：补记结束日选择器里，起始日之前、今天之后的日期都不可选。
  final bool Function(DateTime day)? isEnabled;

  /// 被选中的那一天（画一圈描边）。用于"结束日选择"这类需要回显选择的场景。
  final DateTime? selected;

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
                            recorded: isRecorded?.call(day) ?? true,
                            isToday: isSameDay(day, now),
                            enabled: isEnabled?.call(day) ?? true,
                            selected:
                                selected != null && isSameDay(day, selected!),
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
    required this.recorded,
    required this.isToday,
    this.enabled = true,
    this.selected = false,
    this.onTap,
  });

  final DateTime day;
  final CyclePhase phase;

  /// 经期是否为已记录（false 表示仅预测）。
  final bool recorded;
  final bool isToday;

  /// 不可选的日期：变淡、不响应点击（补记结束日选择器用）。
  final bool enabled;

  /// 当前被选中的日期：画一圈品牌色描边（不覆盖阶段底色）。
  final bool selected;

  final ValueChanged<DateTime>? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    // 视觉规则（2026-11 第二轮调色，目标：远看也能分辨，且"记录"与"预测"不同）：
    //   已记录经期 = period 实心圆 + 白字（最强）
    //   预测经期   = period 淡底 + 1.5px period 描边 + period 字（一眼看出"还没发生"）
    //   排卵日     = ovulation 实心圆 + 白字
    //   易孕期     = fertile 中淡底 + fertile 字（比原来深一档）
    //   今天       = 在外面套一圈 2px 品牌色环（不再用实心，不然会盖掉阶段色）
    //   普通日     = 无底，只有数字
    final bool filled = recorded && phase == CyclePhase.menstrual;

    // 2026-11 第三轮（用户反馈"标记不明显"）：
    //   三种阶段一律用**实心色块**，只靠色相区分 —— 粉=经期、绿=易孕、紫=排卵。
    //   淡底在大屏/强光下几乎看不出来；"预测经期"保留描边，
    //   因为它是唯一"还没发生"的状态，恰恰不该和实心一样重。
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final periodSoft = colors.period.withAlpha(isDark ? 40 : 26);

    final Color background = switch (phase) {
      CyclePhase.menstrual => filled ? colors.period : periodSoft,
      CyclePhase.ovulation => colors.ovulation,
      CyclePhase.fertile => colors.fertile,
      CyclePhase.normal => Colors.transparent,
    };
    final Color foreground = switch (phase) {
      CyclePhase.menstrual => filled ? Colors.white : colors.period,
      CyclePhase.ovulation => Colors.white,
      CyclePhase.fertile => Colors.white,
      CyclePhase.normal => scheme.onSurface.withAlpha(200),
    };
    final bool outlined =
        phase == CyclePhase.menstrual && !filled; // 预测经期用描边

    final isWeekend = day.weekday >= DateTime.saturday;

    // 今天的外环颜色必须与格子底色有对比：
    //   深色主题下 brand 与 period 恰好同色（都是 #F07C90），
    //   若沿用 brand，经期当天的"今天环"会被实心红吞掉 —— 实测截图里看不见。
    //   所以实心格用 onSurface（浅色下近黑、深色下近白），其余用品牌色。
    final Color todayRing = filled
        ? scheme.onSurface.withAlpha(200)
        : colors.brand;

    // 不可选（补记范围外）：整体压淡到 30%，并且不响应点击。
    final bool tappable = enabled && onTap != null;
    final double opacity = enabled ? 1.0 : 0.32;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Center(
        // 结构刻意保持"一层 InkWell + 一层 Container"：
        // 之前多套了一层 Material(shape: CircleBorder()) + Center，
        // 在 1080×1920 的模拟器上出现整个日历格子收不到点击（Material 的
        // 形状裁剪参与了命中测试），页头按钮却正常。这里回到最朴素的写法。
        child: SizedBox(
          width: 40,
          height: 40,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: tappable ? () => onTap!(day) : null,
            child: Opacity(
              opacity: opacity,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: background,
                  border: selected
                      ? Border.all(color: colors.brand, width: 2.5)
                      : isToday
                          ? Border.all(color: todayRing, width: 2)
                          : (outlined
                              ? Border.all(color: colors.period, width: 1.5)
                              : null),
                ),
                child: Text(
                  '${day.day}',
                  style: AppTokens.label.copyWith(
                    color: isToday && phase == CyclePhase.normal
                        ? colors.brand
                        : (phase == CyclePhase.normal && isWeekend
                            ? scheme.onSurface.withAlpha(140)
                            : foreground),
                    fontWeight:
                        isToday || filled ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: AppTokens.spaceL,
      runSpacing: AppTokens.spaceS,
      children: [
        // 图例的色块必须与格子里的画法一一对应，否则用户会更困惑
        _item(context, colors.period, '经期', fill: colors.period),
        _item(
          context,
          colors.period,
          '预测经期',
          fill: colors.period.withAlpha(isDark ? 40 : 26),
          border: colors.period,
        ),
        _item(context, colors.fertile, '易孕期', fill: colors.fertile),
        _item(context, colors.ovulation, '排卵日', fill: colors.ovulation),
        _item(context, scheme.onSurface.withAlpha(120), '普通日', outlined: true),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    Color color,
    String label, {
    Color? fill,
    Color? border,
    bool outlined = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : (fill ?? color),
            border: outlined
                ? Border.all(color: color, width: 1)
                : (border == null ? null : Border.all(color: border, width: 1.5)),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTokens.spaceXs),
        Text(
          label,
          style: AppTokens.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
          ),
        ),
      ],
    );
  }
}
