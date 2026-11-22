// lib/core/widgets/feedback/pill_tag.dart
//
// 胶囊标签。全 App 的"状态标签"只走这一个组件。
//
// 语义色只用 AppColors 里已有的那几个（period / fertile / ovulation /
// calorieOver / brand），不要在这里新增颜色。

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';

enum PillTone { brand, period, fertile, ovulation, over, neutral }

class PillTag extends StatelessWidget {
  const PillTag({
    super.key,
    required this.label,
    this.tone = PillTone.brand,
    this.icon,
    this.dense = false,
    this.onTap,
  });

  final String label;
  final PillTone tone;
  final IconData? icon;

  /// 更小一号（卡片右上角那种）。
  final bool dense;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;

    final Color fg;
    switch (tone) {
      case PillTone.period:
        fg = colors.period;
      case PillTone.fertile:
        fg = colors.fertile;
      case PillTone.ovulation:
        fg = colors.ovulation;
      case PillTone.over:
        fg = colors.calorieOver;
      case PillTone.neutral:
        fg = scheme.onSurface.withAlpha(150);
      case PillTone.brand:
        fg = colors.brand;
    }

    final text = Text(
      label,
      style: (dense ? AppTokens.caption : AppTokens.label).copyWith(
        color: fg,
        fontWeight: FontWeight.w600,
      ),
    );

    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppTokens.spaceS : AppTokens.spaceM,
        vertical: dense ? 2 : AppTokens.spaceXs,
      ),
      decoration: BoxDecoration(
        color: fg.withAlpha(tone == PillTone.neutral ? 18 : 26),
        borderRadius: AppTokens.borderPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: fg),
            const SizedBox(width: AppTokens.spaceXs),
          ],
          text,
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: AppTokens.borderPill,
      child: content,
    );
  }
}
