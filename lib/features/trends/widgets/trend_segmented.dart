// lib/features/trends/widgets/trend_segmented.dart
//
// 分段切换控件（P2-4）。对 SegmentedButton 的薄封装：
// 趋势页三个图共用同一段切换交互，样式收敛在一处，
// 以后再加图（比如睡眠）不用复制样式。

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

class TrendSegmented<T> extends StatelessWidget {
  const TrendSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      segments: [
        for (final e in segments.entries)
          ButtonSegment(value: e.key, label: Text(e.value)),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 图表下的文字摘要块（P2-4 验收：每图带文字摘要，Semantics 可读）。
/// 摘要同时写给看不清图的人和读屏用户，一处生成两处消费。
class TrendSummary extends StatelessWidget {
  const TrendSummary({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Text(
        text,
        style: AppTokens.caption.copyWith(
          color: scheme.onSurface.withAlpha(150),
        ),
      ),
    );
  }
}
