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
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../../../core/widgets/feedback/pill_tag.dart';
import '../../../core/widgets/surface/section_header.dart';
import '../../../core/widgets/surface/soft_card.dart';
import '../../period/data/period_tables.dart' show FlowLevel, PainLevel;
import '../../period/providers/period_providers.dart';
import '../../period/services/period_history_editor.dart';
import '../../period/services/period_prediction_service.dart';
import '../utils/month_matrix.dart';
import '../widgets/month_grid.dart';
import '../widgets/year_overview.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _month = firstDayOfMonth(DateTime.now());

  /// 月视图 / 年视图（计划书 §4.2 的「年视图」）。
  /// 年视图不是用来记录的，是用来回答"这一年规律不规律"。
  bool _yearView = false;

  /// 最近一次滑动的方向：1 = 往后（左滑看下个月/下一年），-1 = 往前。
  /// 只用于进场动画的起始偏移，让"往哪边翻"看起来是对的。
  int _swipeDir = 1;

  /// 左右滑动切月（年视图下切年）。
  ///
  /// 方向约定与主流日历一致：**手指往左划 = 往后翻**。
  /// 用 primaryVelocity 的符号判断，不用位移距离 —— 避免慢慢拖动到一半
  /// 又滑回去也被算作翻页。

  /// 翻页：forward = true 表示往后（下个月/下一年）。
  void _swipeBy(bool forward) {
    setState(() {
      _swipeDir = forward ? 1 : -1;
      if (_yearView) {
        _month = DateTime(_month.year + (forward ? 1 : -1), _month.month);
      } else {
        _month = forward ? nextMonth(_month) : previousMonth(_month);
      }
    });
  }

  // ---- Listener 版的横向滑动（不参与手势竞技场，避免吃掉格子的点击） ----
  Offset? _swipeStart;
  double _swipeDx = 0;
  double _swipeDy = 0;

  void _onSwipeDown(PointerDownEvent e) {
    _swipeStart = e.position;
    _swipeDx = 0;
    _swipeDy = 0;
  }

  void _onSwipeMove(PointerMoveEvent e) {
    final start = _swipeStart;
    if (start == null) return;
    _swipeDx = e.position.dx - start.dx;
    _swipeDy = e.position.dy - start.dy;
  }

  void _onSwipeUp(PointerUpEvent e) {
    final dx = _swipeDx;
    final dy = _swipeDy;
    _clearSwipe();
    // 横向位移够大、且明显大于纵向（否则是纵向滚动列表），才算翻页
    if (dx.abs() < 60) return;
    if (dx.abs() < dy.abs() * 1.4) return;
    _swipeBy(dx < 0);
  }

  void _clearSwipe() {
    _swipeStart = null;
    _swipeDx = 0;
    _swipeDy = 0;
  }

  static const PeriodPredictionService _predictor = PeriodPredictionService();

  @override
  Widget build(BuildContext context) {
    final cycles =
        ref.watch(cyclesProvider).valueOrNull ?? const <CycleInput>[];
    final prediction = ref.watch(predictionProvider);

    // 未结束的经期：显示上延伸到"今天"，否则日历上看不到正在进行的那次
    final displayCycles = _closeOpenCycleAtToday(cycles);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: _yearView ? '回到月视图' : '看全年',
            icon: Icon(
              _yearView ? Icons.calendar_view_month : Icons.grid_view,
            ),
            onPressed: () => setState(() => _yearView = !_yearView),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.pagePadding,
          vertical: AppTokens.spaceM,
        ),
        children: [
          _MonthHeader(
            month: _month,
            yearOnly: _yearView,
            onPrev: () => setState(() {
              _month = _yearView
                  ? DateTime(_month.year - 1, _month.month)
                  : previousMonth(_month);
            }),
            onNext: () => setState(() {
              _month = _yearView
                  ? DateTime(_month.year + 1, _month.month)
                  : nextMonth(_month);
            }),
            onToday: () =>
                setState(() => _month = firstDayOfMonth(DateTime.now())),
          ),
          const SizedBox(height: AppTokens.spaceM),
          // 左右滑动切月：手势包在日历卡外层（不是整页），
          // 左右滑动切月：用 Listener 自己算位移，**不用** GestureDetector 的
          // onHorizontalDrag*。原因：水平拖动识别器会和格子里的 InkWell 抢手势
          // 竞技场，实测在 1080×1920 的设备上"点日期"完全失效（页头按钮、滑动都正常）。
          // Listener 不参与竞技场，只在抬手时判断"这次是不是横向滑动"，点按不受影响。
          Listener(
            onPointerDown: _onSwipeDown,
            onPointerMove: _onSwipeMove,
            onPointerUp: _onSwipeUp,
            onPointerCancel: (_) => _clearSwipe(),
            child: AnimatedSwitcher(
              duration: AppTokens.durBase,
              switchInCurve: AppTokens.curve,
              transitionBuilder: (child, animation) {
                // 从滑动方向"推"进来：左滑（看下个月）内容从右侧进。
                final begin = Offset(0.08 * _swipeDir, 0);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: begin, end: Offset.zero)
                        .animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<String>(
                  '${_yearView ? 'y' : 'm'}-${_month.year}-${_month.month}',
                ),
                child: _yearView
                    ? SoftCard(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.spaceM,
                          AppTokens.spaceM,
                          AppTokens.spaceM,
                          AppTokens.spaceM,
                        ),
                        child: YearOverview(
                          year: _month.year,
                          today: DateTime.now(),
                          isRecorded: (day) =>
                              _isRecordedPeriodDay(day, displayCycles),
                          phaseOfDay: (day) => _predictor.phaseOf(
                            day,
                            prediction: prediction,
                            recordedCycles: displayCycles,
                          ),
                          onTapMonth: (monthStart) => setState(() {
                            _month = firstDayOfMonth(monthStart);
                            _yearView = false;
                          }),
                        ),
                      )
                    : SoftCard(
                        padding: const EdgeInsets.fromLTRB(
                          AppTokens.spaceS,
                          AppTokens.spaceM,
                          AppTokens.spaceS,
                          AppTokens.spaceM,
                        ),
                        child: Column(
                          children: [
                            MonthGrid(
                              month: _month,
                              onTapDay: (day) => _showDay(
                                context,
                                day,
                                prediction,
                                displayCycles,
                              ),
                              isRecorded: (day) =>
                                  _isRecordedPeriodDay(day, displayCycles),
                              phaseOfDay: (day) => _predictor.phaseOf(
                                day,
                                prediction: prediction,
                                recordedCycles: displayCycles,
                              ),
                            ),
                            const SizedBox(height: AppTokens.spaceM),
                            Divider(
                              height: 1,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withAlpha(12),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: AppTokens.spaceM),
                              child: PhaseLegend(),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spaceXl),
          SectionHeader(
            title: '最近周期',
            actionLabel: cycles.isEmpty ? null : '全部历史',
            onAction: () => context.push('/period/history'),
          ),
          if (cycles.isEmpty)
            const SoftCard(
              child: EmptyState(
                compact: true,
                icon: Icons.calendar_month_outlined,
                title: '还没有周期数据',
                message: '在「今日」页记录第一次经期，这里就会亮起来',
              ),
            )
          else
            for (final c in cycles.reversed.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.cardGap),
                child: _CycleTile(cycle: c),
              ),
        ],
      ),
    );
  }

  /// 该天是否落在**已记录**的经期区间内（用于区分"记录"与"预测"）。
  ///
  /// 与 phaseOf 的区别：phaseOf 对两者都返回 menstrual，
  /// 这里只认 cycles 里真实存在的区间；未结束的周期按"到今天为止"算。
  bool _isRecordedPeriodDay(DateTime day, List<CycleInput> cycles) {
    final d = dateOnly(day);
    final today = dateOnly(DateTime.now());
    for (final c in cycles) {
      final start = dateOnly(c.start);
      if (d.isBefore(start)) continue;
      final end = c.end == null ? today : dateOnly(c.end!);
      if (!d.isAfter(end)) return true;
    }
    return false;
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

    // 「今天」与「这一天最多能补几天」在这里算一次：
    //   补记只补历史，结束日不能晚于今天。
    //   2026-11-22 第二轮：补记流程改为"先定开始日，再在日历上选结束日"，
    //   2026-11-22 第二轮：补记流程改为"先定开始日，再在日历上选结束日"，
    //   可选范围由选择器自己算（见 _pickEndDay），不再限制 3–7 天。
    final today0 = dateOnly(DateTime.now());
    final dayStart = dateOnly(day);
    final isFuture = dayStart.isAfter(today0);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final scheme = Theme.of(ctx).colorScheme;

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
                    if (isFuture)
                      Text(
                        '这一天还没到，不能补记。补记只用于填过去的经期。',
                        style: AppTokens.caption.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                        ),
                      )
                    else ...[
                      Text(
                        '忘了记？先把这一天记作开始日，再从日历上选结束日。'
                        '（最长可补到 ${today0.month}月${today0.day}日）',
                        style: AppTokens.caption.copyWith(
                          color: scheme.onSurface.withAlpha(150),
                        ),
                      ),
                      const SizedBox(height: AppTokens.spaceM),
                      SizedBox(
                        width: double.infinity,
                        height: AppTokens.minTouchTarget,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.event_note_outlined),
                          label: Text(
                            '${day.month}月${day.day}日 来经期，选择结束日',
                          ),
                          onPressed: () async {
                            final end = await _pickEndDay(
                              context: ctx,
                              start: dayStart,
                              today: today0,
                            );
                            if (end == null || !ctx.mounted) return;
                            final rangeText = '${day.month}月${day.day}日 – '
                                '${end.month}月${end.day}日'
                                '（${end.difference(dayStart).inDays + 1} 天）';
                            await _applyEdit(
                              ctx,
                              () => ref
                                  .read(periodRepositoryProvider)
                                  .upsertHistoricalPeriod(start: day, end: end),
                              '已补记 $rangeText',
                            );
                          },
                        ),
                      ),
                      if (dayStart == today0)
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
                    ],
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
                        await repo.updateDailyIntensity(day,
                            flowLevel: v.value);
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
                        await repo.updateDailyIntensity(day,
                            painLevel: v.value);
                        ref.invalidate(todayRecordProvider);
                      },
                    ),
                    const SizedBox(height: AppTokens.spaceM),

                    if (!isFuture &&
                        (cycle.end == null ||
                            cycle.end!.isAfter(dateOnly(day))))
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
                    if (isFuture)
                      Text(
                        '这一天还没到，不能设为结束日。',
                        style: AppTokens.caption.copyWith(
                          color: scheme.onSurface.withAlpha(150),
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
                        style: TextButton.styleFrom(
                            foregroundColor: colors.danger),
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

  /// 选择补记的**结束日**（2026-11-22 新流程）。
  ///
  /// 为什么改成"再选一次结束日"：原来只有 3–7 天的快捷 chip，
  /// 但异常经期可能淋漓两三周，用户根本选不出来；而且"持续几天"
  /// 这个抽象概念不如"在日历上点一下结束日"直观。
  ///
  /// 可选范围：`start ≤ day ≤ today`（补记只补历史），
  /// 其余日期在网格里变淡且不可点。返回 null 表示用户放弃。
  Future<DateTime?> _pickEndDay({
    required BuildContext context,
    required DateTime start,
    required DateTime today,
  }) {
    final maxDays = maxBackfillDays(start: start, today: today);
    var cursor = firstDayOfMonth(start);
    DateTime? picked;

    return showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final scheme = Theme.of(ctx).colorScheme;
          final canPrev = cursor.isAfter(firstDayOfMonth(start));
          final canNext = cursor.isBefore(firstDayOfMonth(today));
          final len =
              picked == null ? null : picked!.difference(start).inDays + 1;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spaceM,
                0,
                AppTokens.spaceM,
                AppTokens.spaceL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '选择结束日',
                    style: AppTokens.headline.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: AppTokens.spaceXs),
                  Text(
                    '开始日 ${start.month}月${start.day}日 · '
                    '最长可到 ${today.month}月${today.day}日（$maxDays 天）',
                    style: AppTokens.caption.copyWith(
                      color: scheme.onSurface.withAlpha(150),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceS),
                  Row(
                    children: [
                      IconButton(
                        onPressed: canPrev
                            ? () =>
                                setSheet(() => cursor = previousMonth(cursor))
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        tooltip: '上个月',
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${cursor.year} 年 ${cursor.month} 月',
                            style: AppTokens.title,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: canNext
                            ? () => setSheet(() => cursor = nextMonth(cursor))
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        tooltip: '下个月',
                      ),
                    ],
                  ),
                  MonthGrid(
                    month: cursor,
                    today: today,
                    selected: picked,
                    phaseOfDay: (_) => CyclePhase.normal,
                    isRecorded: (_) => false,
                    cellHeight: 40,
                    isEnabled: (d) {
                      final x = dateOnly(d);
                      return !x.isBefore(start) && !x.isAfter(today);
                    },
                    onTapDay: (d) => setSheet(() => picked = dateOnly(d)),
                  ),
                  const SizedBox(height: AppTokens.spaceM),
                  Text(
                    picked == null
                        ? '在日历上点一天作为结束日'
                        : '结束日 ${picked!.month}月${picked!.day}日 · 共 $len 天',
                    style: AppTokens.body.copyWith(
                      color: picked == null
                          ? scheme.onSurface.withAlpha(150)
                          : Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceM),
                  SizedBox(
                    width: double.infinity,
                    height: AppTokens.minTouchTarget,
                    child: FilledButton(
                      onPressed: picked == null
                          ? null
                          : () => Navigator.of(ctx).pop(picked),
                      child: Text(
                        picked == null
                            ? '请选择结束日'
                            : '补记 ${start.month}月${start.day}日 – '
                                '${picked!.month}月${picked!.day}日（$len 天）',
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('取消'),
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
    this.yearOnly = false,
  });

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  /// 年视图下标题只写年份（写"2026 年 11 月"会让人以为还在月视图）。
  final bool yearOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    Widget roundButton(IconData icon, VoidCallback onTap, String tooltip) {
      return Material(
        color: colors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                icon,
                size: 20,
                color: scheme.onSurface.withAlpha(170),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        roundButton(Icons.chevron_left, onPrev, '上个月'),
        Expanded(
          child: Center(
            child: Text(
              yearOnly ? '${month.year} 年' : '${month.year} 年 ${month.month} 月',
              style: AppTokens.headline.copyWith(
                color: scheme.onSurface,
                fontSize: 18,
              ),
            ),
          ),
        ),
        roundButton(Icons.chevron_right, onNext, '下个月'),
        const SizedBox(width: AppTokens.spaceS),
        TextButton(
          onPressed: onToday,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceM),
            backgroundColor: colors.brandSoft,
            shape: const RoundedRectangleBorder(
              borderRadius: AppTokens.borderPill,
            ),
          ),
          child: const Text('今天'),
        ),
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

    return SoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceL,
        vertical: AppTokens.spaceM,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 36,
            decoration: BoxDecoration(
              color: colors.period.withAlpha(end == null ? 255 : 120),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: AppTokens.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  range,
                  style: AppTokens.title.copyWith(color: scheme.onSurface),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: AppTokens.caption.copyWith(
                      color: scheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (end == null)
            PillTag(
              label: '进行中',
              tone: PillTone.period,
              dense: true,
            ),
        ],
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
