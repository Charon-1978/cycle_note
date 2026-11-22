// lib/core/widgets/surface/soft_card.dart
//
// 统一卡片外观：20 圆角 + 极轻投影 + 1px 描边。
//
// 为什么需要它：改造前每个页面各自写 Container + BoxDecoration，
// 出现了 12/16 两种圆角、三种描边透明度、有的有投影有的没有，
// 放在一起像三个应用拼的。颜色/圆角/阴影全部来自令牌与 AppColors（R10）。

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.spaceL),
    this.onTap,
    this.color,
    this.gradient,
    this.radius = AppTokens.radiusXl,
    this.border = true,
    this.shadow = true,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// 可点击时给水波纹。为 null 时卡片是死的（不抢焦点）。
  final VoidCallback? onTap;

  /// 自定义底色（默认取 `context.colors.surface`）。
  final Color? color;

  /// 渐变底（给"重点卡片"用，如阶段卡）。给了渐变就不再加纯色。
  final Gradient? gradient;

  final double radius;
  final bool border;
  final bool shadow;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final scheme = Theme.of(context).colorScheme;
    final shape = BorderRadius.circular(radius);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? colors.surface) : null,
        gradient: gradient,
        borderRadius: shape,
        border: border
            ? Border.all(
                color: scheme.onSurface.withAlpha(14),
                width: AppTokens.borderWidth,
              )
            : null,
        boxShadow: shadow ? AppTokens.shadowSoft(colors.shadow) : null,
      ),
      clipBehavior: onTap == null ? Clip.none : Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
