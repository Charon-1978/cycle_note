// lib/features/trends/widgets/trend_line_chart.dart
//
// 通用单序列折线图（P2-4）。周期长度 / 体重 / 热量三张图共用一套绘制，
// 不各自造轮子——之前体重图是独立 CustomPaint，热量和周期再来一遍的话
// 坐标轴、越界、空态的处理会各写一份还互相不一致。
//
// 三条防崩纪律（手册 P2-4 禁止项）：
//   1) 空序列 → 交给 EmptyState，这里不画（但 [isEmpty] 允许调用方判空）
//   2) 单点 → 画一个点 + 起值文字，不崩、不画 0 长度线
//   3) 极值 → Y 轴范围至少撑到数据跨度的 15%，不会两点重叠成一条竖线

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 折线图的数据点。[label] 用于无障碍摘要（如 "11-20"）。
class TrendDatum {
  const TrendDatum({required this.value, this.label});
  final double value;
  final String? label;
}

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.data,
    required this.unit,
    required this.semanticName,
    this.height = 200,
    this.valueFormatter,
    this.lineColor,
  });

  final List<TrendDatum> data;

  /// 数值单位，用于轴标签与无障碍摘要（kcal / kg / 天）。
  final String unit;

  /// 无障碍朗读里的图名（如 "体重趋势图"）。
  final String semanticName;

  /// 数值格式化（轴标签用）。默认保留整数。
  final String Function(double)? valueFormatter;

  final double height;
  final Color? lineColor;

  String _fmt(double v) => valueFormatter?.call(v) ?? v.round().toString();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (data.isEmpty) return SizedBox(height: height);

    return Semantics(
      label: semanticName,
      value: _semanticSummary,
      // 图表单独一层重绘边界：页面其余部分（摘要文字、分段控件）变化时不必重画整条折线。
      child: RepaintBoundary(
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: CustomPaint(
            size: Size.infinite,
            painter: _LinePainter(
              data: data,
              lineColor: lineColor ?? scheme.primary,
              gridColor: scheme.onSurface.withAlpha(18),
              labelColor: scheme.onSurface.withAlpha(120),
              format: _fmt,
              unit: unit,
            ),
          ),
        ),
      ),
    );
  }

  String get _semanticSummary {
    final values = data.map((d) => d.value).toList();
    final avg = values.fold(0.0, (s, v) => s + v) / values.length;
    final first = values.first;
    final last = values.last;
    final diff = last - first;
    final dir = diff.abs() < 0.01 ? '持平' : (diff < 0 ? '下降' : '上升');
    return '共 ${data.length} 条，'
        '${_fmt(first)} 到 ${_fmt(last)} $unit，$dir '
        '${_fmt(diff.abs())} $unit，平均 ${_fmt(avg)} $unit';
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.data,
    required this.lineColor,
    required this.gridColor,
    required this.labelColor,
    required this.format,
    required this.unit,
  });

  final List<TrendDatum> data;
  final Color lineColor;
  final Color gridColor;
  final Color labelColor;
  final String Function(double) format;
  final String unit;

  static const double _leftPad = 40;
  static const double _rightPad = 8;
  static const double _topPad = 12;
  static const double _bottomPad = 20;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final n = data.length;

    final plot = Rect.fromLTWH(
      _leftPad,
      _topPad,
      math.max(0, size.width - _leftPad - _rightPad),
      math.max(0, size.height - _topPad - _bottomPad),
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    // Y 轴：至少撑出 15% 跨度 + 10% 上下边距，单点时上下各让 1 个单位
    var lo = data.map((d) => d.value).reduce(math.min);
    var hi = data.map((d) => d.value).reduce(math.max);
    if (n == 1) {
      lo -= 1;
      hi += 1;
    } else if (hi - lo < (hi + lo).abs() * 0.15 + 0.01) {
      final mid = (hi + lo) / 2;
      final span = math.max((hi + lo).abs() * 0.15, 1.0);
      lo = mid - span;
      hi = mid + span;
    }
    final padY = (hi - lo) * 0.1;
    lo -= padY;
    hi += padY;

    Offset pos(int i, double v) => Offset(
          n == 1 ? plot.center.dx : plot.left + plot.width * i / (n - 1),
          plot.bottom - plot.height * ((v - lo) / (hi - lo)),
        );

    // 网格 + 轴标签
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor;
    for (var i = 0; i < 3; i++) {
      final t = i / 2;
      final y = plot.top + plot.height * t;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _drawLabel(canvas, format(hi - (hi - lo) * t),
          Offset(_leftPad - 4, y), alignRight: true);
    }

    // 折线
    if (n >= 2) {
      final path = Path()
        ..moveTo(pos(0, data[0].value).dx, pos(0, data[0].value).dy);
      for (var i = 1; i < n; i++) {
        path.lineTo(pos(i, data[i].value).dx, pos(i, data[i].value).dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = lineColor,
      );
    }

    // 每个点 + 最新点高亮
    final dotPaint = Paint()..color = lineColor.withAlpha(140);
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(pos(i, data[i].value), 2.5, dotPaint);
    }
    final lastPos = pos(n - 1, data.last.value);
    canvas.drawCircle(lastPos, 4, Paint()..color = lineColor);
    canvas.drawCircle(
      lastPos,
      4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withAlpha(200),
    );

    // 首尾 X 标签
    if (n >= 2 && data.first.label != null) {
      _drawLabel(canvas, data.first.label!, Offset(plot.left, size.height - 16));
    }
    if (data.last.label != null) {
      _drawLabel(canvas, data.last.label!,
          Offset(plot.right - 36, size.height - 16));
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset anchor, {
    bool alignRight = false,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 10, textAlign: TextAlign.right),
    )
      ..pushStyle(ui.TextStyle(color: labelColor, fontSize: 10))
      ..addText(text);
    final p = builder.build()..layout(ui.ParagraphConstraints(width: 36));
    canvas.drawParagraph(
      p,
      Offset(alignRight ? anchor.dx - 36 : anchor.dx, anchor.dy - 6),
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) {
    return old.data != data ||
        old.lineColor != lineColor ||
        old.gridColor != gridColor ||
        old.labelColor != labelColor;
  }
}
