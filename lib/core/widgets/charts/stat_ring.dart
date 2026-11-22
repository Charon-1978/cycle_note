// lib/core/widgets/charts/stat_ring.dart
//
// 三段弧热量环：预算（底轨）/ 摄入（主弧）/ 运动（内圈细弧）。
//
// 设计约束（对应 AGENTS.md R10 与 ADR-3）：
//   · 超预算时主弧变 calorieOver（橙），**不是红色**
//   · 所有颜色取自 context.colors，组件内不得出现 Color(0x...)
//   · 组件纯展示，不读 Provider、不查库
//
// 除零保护：budget <= 0 时只画底轨，不做除法。

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';

class StatRing extends StatelessWidget {
  const StatRing({
    super.key,
    required this.budget,
    required this.intake,
    this.burn = 0,
    this.size = 200,
    this.strokeWidth = 12,
    this.burnColor,
    this.centerChild,
    this.animate = true,
  });

  /// 每日预算（kcal）。<= 0 时只显示底轨。
  final double budget;

  /// 已摄入（kcal）。
  final double intake;

  /// 运动消耗（kcal），以内圈细弧表示。
  final double burn;

  final double size;
  final double strokeWidth;
  /// 运动弧颜色。默认取 AppColors.exercise（蓝），与摄入弧（绿）区分开。
  final Color? burnColor;

  final Widget? centerChild;

  /// 关闭动画（用于 golden test）。
  final bool animate;

  /// 摄入进度 0..1。
  double get _intakeProgress {
    if (budget <= 0) return 0;
    return (intake / budget).clamp(0.0, 1.0);
  }

  /// 运动进度 0..1（相对预算）。
  double get _burnProgress {
    if (budget <= 0) return 0;
    return (burn / budget).clamp(0.0, 1.0);
  }

  bool get _isOver => budget > 0 && intake > budget;

  /// 主弧颜色：超预算用橙（calorieOver），**绝不使用 danger（红）**。
  ///
  /// 单独抽出来是为了让它可被单测断言（ADR-3 的回归保护）：
  /// 未来任何人把它改成红色，测试都会失败。
  @visibleForTesting
  Color resolveArcColor(AppColors colors) =>
      _isOver ? colors.calorieOver : colors.calorieOk;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final mainColor = resolveArcColor(colors);

    final ring = SizedBox(
      width: size,
      height: size,
      child: animate
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: AppTokens.durBase,
              curve: AppTokens.curve,
              builder: (context, t, _) => _buildCanvas(
                colors: colors,
                mainColor: mainColor,
                factor: t,
              ),
            )
          : _buildCanvas(colors: colors, mainColor: mainColor, factor: 1),
    );

    return Semantics(
      label: '热量环',
      value: _semanticValue,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ring,
          if (centerChild != null) centerChild!,
        ],
      ),
    );
  }

  String get _semanticValue {
    if (budget <= 0) return '尚未设置每日预算';
    final remain = budget - intake;
    final overshoot = remain < 0 ? -remain : 0.0;
    final buf = StringBuffer()
      ..write('预算 ${budget.round()} 千卡，已摄入 ${intake.round()} 千卡');
    if (burn > 0) buf.write('，运动消耗 ${burn.round()} 千卡');
    buf.write(overshoot > 0
        ? '，已超出 ${overshoot.round()} 千卡'
        : '，还可摄入 ${remain.round()} 千卡');
    return buf.toString();
  }

  Widget _buildCanvas({
    required AppColors colors,
    required Color mainColor,
    required double factor,
  }) {
    return CustomPaint(
      size: Size.square(size),
      painter: _RingPainter(
        intakeProgress: _intakeProgress * factor,
        burnProgress: _burnProgress * factor,
        mainColor: mainColor,
        // 有预算时底轨用品牌色的淡影（"容量"的感觉），没有预算才用中性轨。
        // 之所以不用纯灰：0 摄入时整环是灰的，首屏看起来像"没数据"。
        trackColor: budget > 0 ? colors.brand.withAlpha(26) : colors.track,
        // 运动弧单独用 exercise（蓝）：摄入弧是 calorieOk（绿），同色会糊成一条
        burnColor: burnColor ?? colors.exercise,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.intakeProgress,
    required this.burnProgress,
    required this.mainColor,
    required this.trackColor,
    required this.burnColor,
    required this.strokeWidth,
  });

  final double intakeProgress;
  final double burnProgress;
  final Color mainColor;
  final Color trackColor;
  final Color burnColor;
  final double strokeWidth;

  static const double _startAngle = -math.pi / 2; // 12 点方向
  static const double _fullSweep = 2 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.shortestSide - strokeWidth) / 2;
    if (outerRadius <= 0) return; // 尺寸异常时直接返回，避免负半径崩溃

    // 1) 底轨（预算）
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, outerRadius, track);

    // 2) 主弧（摄入）
    if (intakeProgress > 0) {
      final main = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = mainColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        _startAngle,
        _fullSweep * intakeProgress,
        false,
        main,
      );
    }

    // 3) 内圈细弧（运动消耗）
    final innerWidth = strokeWidth * 0.55;
    final innerRadius = outerRadius - strokeWidth / 2 - innerWidth / 2 - 4;
    if (burnProgress > 0 && innerRadius > 2) {
      final burnPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerWidth
        ..strokeCap = StrokeCap.round
        ..color = burnColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        _startAngle,
        _fullSweep * burnProgress,
        false,
        burnPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.intakeProgress != intakeProgress ||
        old.burnProgress != burnProgress ||
        old.mainColor != mainColor ||
        old.trackColor != trackColor ||
        old.burnColor != burnColor ||
        old.strokeWidth != strokeWidth;
  }
}

