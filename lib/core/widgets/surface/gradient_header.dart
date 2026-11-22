// lib/core/widgets/surface/gradient_header.dart
//
// 首屏渐变头（品牌色 + 柔和光斑 + 只圆下缘）。
//
// 用在「今日」和「我的」两页的顶部：这是用户每天第一眼看的地方，
// 有颜色的头部能立刻区分"我在哪一页"，也给下面的白卡一个安静底色。
//
// 实现要点：
//   · 光斑用两层带 alpha 的圆形，不引入 blur（低端机 blur 会掉帧）；
//   · 颜色只从 AppColors.heroStart/heroEnd 取，深浅色各一套（R10）。

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.padding,
    this.bottomRadius = AppTokens.radiusXxl,
  });

  final Widget child;

  /// 留空时自动补状态栏高度 —— 本组件通常是没有 AppBar 的页面顶部，
  /// 不补的话标题会被状态栏文字压住（1080x2400 上实测会重叠）。
  final EdgeInsetsGeometry? padding;

  final double bottomRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectivePadding = padding ??
        EdgeInsets.fromLTRB(
          AppTokens.pagePadding,
          MediaQuery.paddingOf(context).top + AppTokens.spaceS,
          AppTokens.pagePadding,
          AppTokens.spaceXxl + AppTokens.spaceL,
        );

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(bottomRadius),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.heroStart, colors.heroEnd],
          ),
        ),
        child: Stack(
          children: [
            // 右上 / 左下两枚光斑：给纯渐变一点呼吸感，避免"色块感"
            Positioned(
              top: -60,
              right: -30,
              child: _Blob(size: 160, color: Colors.white.withAlpha(26)),
            ),
            Positioned(
              bottom: -70,
              left: -20,
              child: _Blob(size: 140, color: Colors.white.withAlpha(18)),
            ),
            Padding(padding: effectivePadding, child: child),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
