// lib/features/calendar/pages/calendar_page.dart
//
// 「日历」—— 看 + 补记。
//
// P1-1 时这里只负责「看」，记录统一在「今日」。实测发现一个真实缺口：
// 用户忘了记、想补上个月的经期时，日历点进去只有一句「知道了」，无路可走；
// 而「今日」页只认「今天」。
//
// 因此这里补上**历史补记**（P4-1）：
//   · 点任意一天 → 弹层里给出「经期从这天开始 / 持续几天」的补记；
//   · 该日已在经期内 → 可「经期到这天结束」或「删除这段」；
//   · 写入后周期表会被重算（相邻 cycleLength），预测与易孕期随之更新。
//
// 数据来源：cyclesProvider（已记录周期）+ predictionProvider（预测）。
// 着色规则由 PeriodPredictionService.phaseOf 统一判定，与「今日」页同源，
// 不会出现"今日说是易孕期、日历却标成普通日"这种不一致。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../period/data/period_tables.dart' show FlowLevel, PainLevel;
import '../../period/providers/period_providers.dart';
import '../../period/services/period_history_editor.dart';
import '../../period/services/period_prediction_service.dart';
import '../utils/month_matrix.dart';
import '../widgets/month_grid.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month = firstDayOfMonth(DateTime.now());

  static const PeriodPredictionService _predictor = PeriodPredictionService();

  @override
  Widget build(BuildContext context) {
    final cycles = ref.watch(cyclesProvider).valueOrNull ?? const <CycleInput>[];
    final prediction = ref.watch(predictionProvider);

    // 未结束的经期：显示上延伸到"今天"，否则日历上看不到正在进行的那次
    final displayCycles = _closeOpenCycleAtToday(cycles);

    return Scaffold(
      appBar: AppBar(title: const Text('日历'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.pagePadding,
          vertical: AppTokens.spaceM,
        ),
        children: [
          _MonthHeader(
            month: _month,
            onPrev: () => setState(() => _month = previousMonth(_month)),
            onNext: () => setState(() => _month = nextMonth(_month)),
            onToday: () =>
                setState(() => _month = firstDayOfMonth(DateTime.now())),
          ),
          const SizedBox(height: AppTokens.spaceM),
          MonthGrid(
            month: _month,
            onTapDay: (day) => _showDay(context, day, prediction, displayCycles),
            phaseOfDay: (day) => _predictor.phaseOf(
              day,
              prediction: prediction,
              recordedCycles: displayCycles,
            ),
          ),
          const SizedBox(height: AppTokens.spaceM),
          const PhaseLegend(),
          const SizedBox(height: AppTokens.spaceXl),
          Text(
            '最近周期',
            style: AppTokens.title.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTokens.spaceS),
          if (cycles.isEmpty)
            const EmptyState(
              compact: true,
              icon: Icons.calendar_month_outlined,
              title: '还没有周期数据',
              message: '在「今日」页记录第一次经期，这里就会亮起来',
            )
          else
            for (final c in cycles.reversed.take(4)) _CycleTile(cycle: c),
        ],
      ),
    );
  }

  /// 把"未结束"的周期补上 endDate = 今天（仅用于显示，不写库）。
  List<CycleInput> _closeOpenCycleAtToday(List<CycleInput> cycles) {
    if (cycles.isEmpty) return cycles;

    final now = DateTime.now();
    final today = dateOnly(now);

    final result = <CycleInput>[];
    for (var i = 0; i < cycles.length; i++) {
      final c = cycles[i];
      final isLast = i == cycles.length - 1;
      if (isLast && c.end == null && !today.isBefore(dateOnly(c.start))) {
        result.add(CycleInput(
          start: c.start,
          end: today,
          cycleLength: c.cycleLength,
          periodLength: c.periodLength,
        ));
      } else {
        result.add(c);
      }
    }
    return result;
  }

  Future<void> _showDay(
    BuildContext context,
    DateTime day,
    PeriodPrediction? prediction,
    List<CycleInput> cycles,
  ) async {
    final phase = _predictor.phaseOf(
      day,
      prediction: prediction,
      recordedCycles: cycles,
    );
    final colors = context.colors;

    final accent = switch (phase) {
      CyclePhase.menstrual => colors.period,
      CyclePhase.ovulation => colors.ovulation,
      CyclePhase.fertile => colors.fertile,
      CyclePhase.normal => Theme.of(context).colorScheme.onSurface,
    };

    const editor = PeriodHistoryEditor();
    final cycle = editor.cycleAt(cycles, day);
    final repo = ref.read(periodRepositoryProvider);
    // 该日已有的经量/痛经记录（美柚的记录面板就是逐日三项：流量、痛感、备注）
    final dayRecord = await repo.recordOf(day);
    // context 是本方法参数，必须用它的 mounted（不是 State.mounted）
    if (!context.mounted) return;
    var flow = FlowLevel.fromValue(dayRecord?.flowLevel);
    var pain = PainLevel.fromValue(dayRecord?.painLevel);
    // 默认持续天数取该周期已有天数（编辑场景），否则用常见值 5
    var duration = (cycle?.resolvedPeriodLength ?? 5).clamp(3, 7);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final scheme = Theme.of(ctx).colorScheme;
          final end = day.add(Duration(days: duration - 1));
          final rangeText =
              '${day.month}月${day.day}日 – ${end.month}月${end.day}日';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceL,
                0,
                AppTokens.spaceL,
                AppTokens.spaceL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${day.year} 年 ${day.month} 月 ${day.day} 日',
                    style: AppTokens.headline.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: AppTokens.spaceS),
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
                      Text(phase.label,
                          style: AppTokens.label.copyWith(color: accent)),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spaceS),
                  Text(
                    _phaseHint(phase),
                    style: AppTokens.body.copyWith(
                      color: scheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceL),

                  if (cycle == null) ...[
                    // ---- 补记：这一天不在任何已记录的经期里 ----
                    Text('补记经期', style: AppTokens.title),
                    const SizedBox(height: AppTokens.spaceXs),
                    Text(
                      '忘了记？选一个持续天数，日历与预测会一起更新。',
                      style: AppTokens.caption.copyWith(
                        color: scheme.onSurface.withAlpha(150),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceM),
                    Wrap(
                      spacing: AppTokens.spaceS,
                      children: [
                        for (final d in const [3, 4, 5, 6, 7])
                          ChoiceChip(
                            label: Text('$d 天'),
                            selected: duration == d,
                            onSelected: (_) =>
                                setSheetState(() => duration = d),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.spaceM),
                    SizedBox(
                      width: double.infinity,
                      height: AppTokens.minTouchTarget,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text('补记 $rangeText（$duration 天）'),
                        onPressed: () => _applyEdit(
                          ctx,
                          () => ref
                              .read(periodRepositoryProvider)
                              .upsertHistoricalPeriod(start: day, end: end),
                          '已补记 $rangeText',
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => _applyEdit(
                          ctx,
                          () => ref
                              .read(periodRepositoryProvider)
                              .upsertHistoricalPeriod(start: day),
                          '已记录经期开始（结束日可稍后补）',
                        ),
                        child: const Text('只记开始日'),
                      ),
                    ),
                  ] else ...[
                    // ---- 这一天已在某段经期内 ----
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppTokens.spaceM),
                      decoration: BoxDecoration(
                        color: colors.period.withAlpha(20),
                        borderRadius: AppTokens.borderS,
                      ),
                      child: Text(
                        '这段经期：${_rangeOf(cycle)}'
                        '${cycle.end == null ? '（进行中）' : ''}',
                        style: AppTokens.body.copyWith(color: colors.period),
                      ),
                    ),
                    const SizedBox(height: AppTokens.spaceM),

                    // 逐日记录：经量与痛经（美柚记录面板的核心三项之二）
                    _LevelPicker<FlowLevel>(
                      label: '这天经量',
                      values: FlowLevel.values,
                      selected: flow,
                      labelOf: (v) => v.label,
                      onSelected: (v) async {
                        setSheetState(() => flow = v);
                        await repo.updateDailyIntensity(day, flowLevel: v.value);
                        ref.invalidate(todayRecordProvider);
                      },
                    ),
                    const SizedBox(height: AppTokens.spaceS),
                    _LevelPicker<PainLevel>(
                      label: '这天痛经',
                      values: PainLevel.values,
                      selected: pain,
                      labelOf: (v) => v.label,
                      onSelected: (v) async {
                        setSheetState(() => pain = v);
                        await repo.updateDailyIntensity(day, painLevel: v.value);
                        ref.invalidate(todayRecordProvider);
                      },
                    ),
                    const SizedBox(height: AppTokens.spaceM),

                    if (cycle.end == null ||
                        cycle.end!.isAfter(dateOnly(day)))
                      SizedBox(
                        width: double.infinity,
                        height: AppTokens.minTouchTarget,
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.event_busy_outlined),
                          label: const Text('经期到这天结束'),
                          onPressed: () => _applyEdit(
                            ctx,
                            () => repo.endPeriodAt(
                              cycleStart: cycle.start,
                              date: day,
                            ),
                            '已把结束日设为 ${day.month}月${day.day}日',
                          ),
                        ),
                      ),
                    if (cycle.end != null)
                      Center(
                        child: TextButton(
                          onPressed: () => _applyEdit(
                            ctx,
                            () => repo.clearPeriodEnd(cycle.start),
                            '已撤销结束日（改回进行中）',
                          ),
                          child: const Text('撤销结束日'),
                        ),
                      ),
                    Center(
                      child: TextButton(
                        onPressed: () => _confirmDelete(
                          ctx,
                          cycle.start,
                          _rangeOf(cycle),
                        ),
                        style:
                            TextButton.styleFrom(foregroundColor: colors.danger),
                        child: const Text('删除这段经期'),
                      ),
                    ),
                  ],

                  const SizedBox(height: AppTokens.spaceM),
                  SizedBox(
                    width: double.infinity,
                    height: AppTokens.minTouchTarget,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('关闭'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _phaseHint(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return '这一天已在经期内，可直接改结束日或删除';
      case CyclePhase.ovulation:
        return '按下次经期倒推 14 天得出的预测日，仅供参考';
      case CyclePhase.fertile:
        return '排卵前 5 天到排卵后 1 天，属预测范围，仅供参考';
      case CyclePhase.normal:
        return '未记录为经期，也不在预测的易孕期内';
    }
  }

  static String _rangeOf(CycleInput c) {
    final start = dateOnly(c.start);
    final end = c.end == null ? null : dateOnly(c.end!);
    if (end == null) return '${start.month}月${start.day}日 开始';
    return '${start.month}月${start.day}日 – ${end.month}月${end.day}日';
  }

  /// 执行一次补记/编辑，然后让日历与预测一起刷新。
  Future<void> _applyEdit(
    BuildContext sheetCtx,
    Future<PeriodEditResult> Function() action,
    String successText,
  ) async {
    final result = await action();
    if (!mounted || !sheetCtx.mounted) return;

    Navigator.of(sheetCtx).pop();
    final messenger = ScaffoldMessenger.of(context);
    if (!result.ok) {
      messenger.showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }

    // cyclesProvider 是上游：predictionProvider / 今日页阶段都从它派生，
    // 只 invalidate 这一个就能让「易孕期/排卵日」同步更新。
    ref.invalidate(cyclesProvider);
    ref.invalidate(inPeriodProvider);
    ref.invalidate(todayRecordProvider);
    messenger.showSnackBar(SnackBar(content: Text(successText)));
  }

  Future<void> _confirmDelete(
    BuildContext sheetCtx,
    DateTime start,
    String rangeText,
  ) async {
    final ok = await showDialog<bool>(
      context: sheetCtx,
      builder: (c) => AlertDialog(
        title: const Text('删除这段经期？'),
        content: Text('$rangeText 的记录会被删除，日历与预测将随之变化。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!sheetCtx.mounted) return;
    await _applyEdit(
      sheetCtx,
      () => ref.read(periodRepositoryProvider).deleteHistoricalPeriod(start),
      '已删除 $rangeText',
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          tooltip: '上个月',
        ),
        Expanded(
          child: Center(
            child: Text(
              '${month.year} 年 ${month.month} 月',
              style: AppTokens.headline.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: '下个月',
        ),
        TextButton(onPressed: onToday, child: const Text('今天')),
      ],
    );
  }
}

class _CycleTile extends StatelessWidget {
  const _CycleTile({required this.cycle});

  final CycleInput cycle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    final start = dateOnly(cycle.start);
    final end = cycle.end == null ? null : dateOnly(cycle.end!);
    final periodLength = cycle.resolvedPeriodLength;

    final range = end == null
        ? '${start.month}月${start.day}日 开始'
        : '${start.month}月${start.day}日 – ${end.month}月${end.day}日';

    final detail = [
      if (periodLength != null) '经期 $periodLength 天',
      if (cycle.cycleLength != null) '周期 ${cycle.cycleLength} 天',
      if (end == null) '进行中',
    ].join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 8,
        height: 36,
        decoration: BoxDecoration(
          color: colors.period.withAlpha(end == null ? 255 : 120),
          borderRadius: BorderRadius.circular(AppTokens.radiusS),
        ),
      ),
      title: Text(range, style: AppTokens.body.copyWith(color: scheme.onSurface)),
      subtitle: detail.isEmpty
          ? null
          : Text(
              detail,
              style: AppTokens.caption.copyWith(
                color: scheme.onSurface.withAlpha(140),
              ),
            ),
    );
  }
}

/// 一行「标签 + 单选 chips」。经量 / 痛经共用。
///
/// 选择状态由外层 StatefulBuilder 持有，本组件只负责画：
/// 这样点一下 chip 能同时更新界面与落库，不用把状态塞进 State。
class _LevelPicker<T> extends StatelessWidget {
  const _LevelPicker({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final String label;
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTokens.caption.copyWith(
            color: scheme.onSurface.withAlpha(150),
          ),
        ),
        const SizedBox(height: AppTokens.spaceXs),
        Wrap(
          spacing: AppTokens.spaceS,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(labelOf(v)),
                selected: v == selected,
                onSelected: (_) => onSelected(v),
              ),
          ],
        ),
      ],
    );
  }
}
