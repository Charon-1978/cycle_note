// lib/core/widgets/input/quick_action_grid.dart
//
// 一排快捷动作：圆角色底图标 + 一行文案。
//
// 用途：今日页的「记体重 / 记运动 / 记饮食 / 记经期」。
// 为什么不用几个 OutlinedButton 并排：
//   按钮是"命令"，图标块是"入口"。主页上后者更省视线，也更容易点到
//   （整块可点，不用精确命中文字）。

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';

class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// 图标底色，默认品牌色。
  final Color? tint;
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.actions,
    this.spacing = AppTokens.spaceS,
  });

  final List<QuickAction> actions;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: _Tile(action: actions[i])),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.action});

  final QuickAction action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = action.tint ?? context.colors.brand;

    return InkWell(
      onTap: action.onTap,
      borderRadius: AppTokens.borderL,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceS),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tint.withAlpha(24),
                borderRadius: AppTokens.borderL,
              ),
              child: Icon(action.icon, size: 24, color: tint),
            ),
            const SizedBox(height: AppTokens.spaceS),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTokens.label.copyWith(
                color: scheme.onSurface.withAlpha(190),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
