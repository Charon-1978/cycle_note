// lib/features/weight_loss/widgets/weight_trend_chart.dart
//
// 体重趋势折线（P1-4）。
//
// 三条视觉纪律（手册 P1-4 禁止项）：
//   1) 主视觉是 **7 日移动平均**，不是原始体重。体重每天 ±1 kg 是生理波动，
//      直接画原始线会把正常波动画成"反弹"，制造不必要的焦虑。
//   2) 体重上升用中性灰 weightUp（ADR-3），**绝不用红**。
//      红色只留给破坏性操作，这是全项目写进 AGENTS.md 的约定。
//   3) 目标体重用虚线，与"已记录"在视觉上可区分。
//
// 组件纯展示：不读 Provider、不查库、不做数据加工 —— 数据由调用方给
// （正好对应 repository.weightTrend 的输出，验收要求两者一致）。

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../data/weight_loss_repository.dart' show WeightPoint;

class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({
    super.key,
    required this.points,
    this.targetWeightKg,
    this.height = 200,
  });

  final List<WeightPoint> points;
  final double? targetWeightKg;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '体重趋势图',
      value: _semanticValue,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: CustomPaint(
          size: Size.infinite,
          painter: _TrendPainter(
            points: points,
            targetWeightKg: targetWeightKg,
            lineColor: scheme.primary,
            rawColor: scheme.onSurface.withAlpha(89), // ≈ 0.35
            targetColor: scheme.onSurface.withAlpha(110),
            gridColor: scheme.onSurface.withAlpha(18),
            labelColor: scheme.onSurface.withAlpha(120),
          ),
        ),
      ),
    );
  }

  String get _semanticValue {
    if (points.isEmpty) return '还没有体重数据';
    final first = points.first;
    final last = points.last;
    final diff = last.trend - first.trend;
    final dir = diff.abs() < 0.05 ? '持平' : (diff < 0 ? '下降' : '上升');
    return '趋势$dir${diff.abs().toStringAsFixed(1)} 公斤，'
        '最新 ${last.trend.toStringAsFixed(1)} 公斤，'
        '共 ${points.length} 条记录';
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.targetWeightKg,
    required this.lineColor,
    required this.rawColor,
    required this.targetColor,
    required this.gridColor,
    required this.labelColor,
  });

  final List<WeightPoint> points;
  final Color labelColor;
  final double? targetWeightKg;
  final Color lineColor;
  final Color rawColor;
  final Color targetColor;
  final Color gridColor;

  static const double _leftPad = 34;
  static const double _rightPad = 8;
  static const double _topPad = 12;
  static const double _bottomPad = 20;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final plot = Rect.fromLTWH(
      _leftPad,
      _topPad,
      math.max(0, size.width - _leftPad - _rightPad),
      math.max(0, size.height - _topPad - _bottomPad),
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    // ---- Y 轴范围：原始 + 趋势 + 目标线一起算，并把范围撑到至少 2 kg ----
    final values = <double>[
      for (final p in points) ...[p.raw, p.trend],
      if (targetWeightKg != null) targetWeightKg!,
    ];
    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 2) {
      final mid = (hi + lo) / 2;
      lo = mid - 1;
      hi = mid + 1;
    }
    final padY = (hi - lo) * 0.12;
    lo -= padY;
    hi += padY;

    Offset pos(int i, double v) => Offset(
          plot.left + plot.width * (points.length == 1 ? 0.5 : i / (points.length - 1)),
          plot.bottom - plot.height * ((v - lo) / (hi - lo)),
        );

    // ---- 网格与刻度（3 条横线，含数值） ----
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor;
    for (var i = 0; i < 3; i++) {
      final t = i / 2;
      final y = plot.top + plot.height * t;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      final v = hi - (hi - lo) * t;
      _drawLabel(canvas, v.toStringAsFixed(0),
          Offset(_leftPad - 4, y), size, alignRight: true);
    }

    // ---- 目标体重虚线 ----
    if (targetWeightKg != null) {
      final y = plot.bottom - plot.height * ((targetWeightKg! - lo) / (hi - lo));
      _drawDashed(
        canvas,
        Offset(plot.left, y),
        Offset(plot.right, y),
        paint: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = targetColor,
      );
    }

    // ---- 原始体重：细线 + 小点（弱化，避免喧宾夺主） ----
    if (points.length >= 2) {
      final rawPath = Path()
        ..moveTo(pos(0, points[0].raw).dx, pos(0, points[0].raw).dy);
      for (var i = 1; i < points.length; i++) {
        rawPath.lineTo(pos(i, points[i].raw).dx, pos(i, points[i].raw).dy);
      }
      canvas.drawPath(
        rawPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = rawColor,
      );
    }
    final dotPaint = Paint()..color = rawColor;
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(pos(i, points[i].raw), 2, dotPaint);
    }

    // ---- 7 日移动平均：主视觉 ----
    if (points.length >= 2) {
      final trendPath = Path()
        ..moveTo(pos(0, points[0].trend).dx, pos(0, points[0].trend).dy);
      for (var i = 1; i < points.length; i++) {
        trendPath.lineTo(pos(i, points[i].trend).dx, pos(i, points[i].trend).dy);
      }
      canvas.drawPath(
        trendPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = lineColor,
      );
    }

    // ---- 最新一个点加实心标记（"我现在在哪"） ----
    final lastPos = pos(points.length - 1, points.last.trend);
    canvas.drawCircle(lastPos, 4, Paint()..color = lineColor);
    canvas.drawCircle(
      lastPos,
      4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withAlpha(200),
    );
  }

  void _drawDashed(
    Canvas canvas,
    Offset from,
    Offset to, {
    required Paint paint,
    double dashWidth = 5,
    double gapWidth = 4,
  }) {
    final total = (to - from).distance;
    if (total <= 0) return;
    final unit = (to - from) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final end = math.min(drawn + dashWidth, total);
      canvas.drawLine(from + unit * drawn, from + unit * end, paint);
      drawn = end + gapWidth;
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset anchor,
    Size size, {
    required bool alignRight,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontSize: 10,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
      ),
    )
      ..pushStyle(
        ui.TextStyle(color: labelColor, fontSize: 10),
      )
      ..addText(text);
    final p = builder.build()..layout(ui.ParagraphConstraints(width: 30));
    canvas.drawParagraph(
      p,
      Offset(alignRight ? anchor.dx - 30 : anchor.dx, anchor.dy - 6),
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) {
    return old.points != points ||
        old.targetWeightKg != targetWeightKg ||
        old.lineColor != lineColor ||
        old.rawColor != rawColor ||
        old.targetColor != targetColor ||
        old.labelColor != labelColor;
  }
}
