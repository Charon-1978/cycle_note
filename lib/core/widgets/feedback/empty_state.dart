// lib/core/widgets/feedback/empty_state.dart
//
// 统一空状态。所有「还没有数据」的地方都必须用它，禁止各页面自己画。
//
// 为什么强制统一（可行性计划书 D7）：
//   月记原本在数据不足时显示空图表，用户不知道下一步该做什么。
//   空状态 = 解释 + 一个明确动作，这是留存的第一道关口。

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.icon = Icons.inbox_outlined,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// 为空时不显示按钮。
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 紧凑模式：用于卡片内部（图标小、间距小）。
  final bool compact;

  bool get _hasAction => actionLabel != null && onAction != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = compact ? 28.0 : 44.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTokens.spaceL,
        vertical: compact ? AppTokens.spaceL : AppTokens.spaceXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            // 用 withAlpha 而非 withOpacity/withValues：
            // 前者在所有 Flutter 版本一致且不会触发弃用告警。
            color: scheme.onSurface.withAlpha(72),
          ),
          SizedBox(height: compact ? AppTokens.spaceS : AppTokens.spaceM),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTokens.title.copyWith(color: scheme.onSurface),
          ),
          if (message != null) ...[
            const SizedBox(height: AppTokens.spaceXs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTokens.body.copyWith(
                color: scheme.onSurface.withAlpha(153),
              ),
            ),
          ],
          if (_hasAction) ...[
            SizedBox(height: compact ? AppTokens.spaceM : AppTokens.spaceL),
            FilledButton.tonal(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppTokens.minTouchTarget),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spaceXl,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
                textStyle: AppTokens.label,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
