// lib/features/weight_loss/widgets/date_strip.dart
//
// 日期条（P2-1）：7 天餐单的"选天"控件。
//
// 为什么不用 TabBar：7 天的标签会挤爆一行，而且这里需要"今天/明天"这种
// 相对日期 + 周几 + 月日三段信息，TabBar 的布局给不了。
//
// 组件纯展示，选中态由调用方持有（页面要在换天时做联动）。

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

class DateStrip extends StatelessWidget {
  const DateStrip({
    super.key,
    required this.dates,
    required this.selected,
    required this.onChanged,
  });

  final List<DateTime> dates;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: AppTokens.minTouchTarget * 1.3,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, i) {
          final d = dates[i];
          final active = i == selected;
          final diff = d.difference(todayDate).inDays;
          final rel = diff == 0 ? '今天' : (diff == 1 ? '明天' : null);

          return Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? AppTokens.pagePadding : 0,
              right: i == dates.length - 1 ? AppTokens.pagePadding : 0,
            ),
            child: _DayChip(
              weekday: _weekday(d.weekday),
              date: '${d.month}/${d.day}',
              relative: rel,
              active: active,
              onTap: () => onChanged(i),
            ),
          );
        },
      ),
    );
  }

  static String _weekday(int w) => const [
        '周一',
        '周二',
        '周三',
        '周四',
        '周五',
        '周六',
        '周日',
      ][w - 1];
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.weekday,
    required this.date,
    required this.active,
    required this.onTap,
    this.relative,
  });

  final String weekday;
  final String date;
  final String? relative;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final bg = active ? scheme.primary : scheme.surface;
    final fg = active ? scheme.onPrimary : scheme.onSurface;

    return Semantics(
      selected: active,
      button: true,
      label: '$relative$weekday $date',
      child: InkWell(
        borderRadius: AppTokens.borderM,
        onTap: onTap,
        child: Container(
          width: 72,
          margin: const EdgeInsets.symmetric(horizontal: AppTokens.spaceXs),
          padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceS),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppTokens.borderM,
            border: Border.all(
              width: AppTokens.borderWidth,
              color: active
                  ? scheme.primary
                  : scheme.onSurface.withAlpha(28),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                relative ?? weekday,
                style: AppTokens.label.copyWith(color: fg),
              ),
              const SizedBox(height: 2),
              Text(
                date,
                style: AppTokens.caption.copyWith(
                  color: fg.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
