// test/tools/gen_icons_test.dart
//
// 品牌图标生成器（一次性工具，留在仓库里是为了"图标可以随时重新生成"）。
//
// 为什么用 Dart 画而不是设计稿：图标是几何图形（渐变圆角底 + 月牙 + 周期点），
// 用矢量重绘能精确控制每个尺寸的清晰度，也不引入图像处理依赖。
// 运行：flutter test test/tools/gen_icons_test.dart
//
// 产物：
//   · mipmap-*/ic_launcher.png            经典图标（自带圆角）
//   · mipmap-*/ic_launcher_foreground.png 自适应图标前景（透明，内容在中央 66% 安全区）
//   · assets/branding/icon_1024.png       商店/分享用大图

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 玫瑰色渐变（与 app_colors 的 period 色系一致：柔和、不刺眼）
const _bgTop = Color(0xFFF4B6C2);
const _bgBottom = Color(0xFFC2545E);

/// 各 density 的经典图标边长
const _legacy = <String, int>{
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

/// 自适应图标前景：108dp 画布，内容须落在中央 66dp 安全区内
const _foreground = <String, int>{
  'mipmap-mdpi': 108,
  'mipmap-hdpi': 162,
  'mipmap-xhdpi': 216,
  'mipmap-xxhdpi': 324,
  'mipmap-xxxhdpi': 432,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('生成品牌图标', (tester) async {
    await tester.runAsync(() async {
      final res = Directory('android/app/src/main/res');

      for (final e in _legacy.entries) {
        final dir = Directory('${res.path}/${e.key}');
        await dir.create(recursive: true);
        final png = await _render(
          size: e.value.toDouble(),
          rounded: true,
          contentScale: 1.0,
        );
        await File('${dir.path}/ic_launcher.png').writeAsBytes(png);
      }

      for (final e in _foreground.entries) {
        final dir = Directory('${res.path}/${e.key}');
        await dir.create(recursive: true);
        // 内容缩到 66%：自适应图标按 72dp 裁切，超出会切边
        final png = await _render(
          size: e.value.toDouble(),
          rounded: false,
          contentScale: 0.66,
          transparent: true,
        );
        await File('${dir.path}/ic_launcher_foreground.png').writeAsBytes(png);
      }

      final branding = Directory('assets/branding');
      await branding.create(recursive: true);
      final big = await _render(size: 1024, rounded: true, contentScale: 1.0);
      await File('${branding.path}/icon_1024.png').writeAsBytes(big);
    });
  });
}

/// 画一张图标。
///
/// [rounded] 圆角方形底（经典图标需要，自适应图标不能有）；
/// [transparent] 只画图形不画底；[contentScale] 图形相对画布的比例。
Future<List<int>> _render({
  required double size,
  required bool rounded,
  required double contentScale,
  bool transparent = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (!transparent) {
    final rect = Rect.fromLTWH(0, 0, size, size);
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rounded ? size * 0.22 : 0),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(size, size),
          const [_bgTop, _bgBottom],
        ),
    );
  }

  final box = size * contentScale;
  final left = (size - box) / 2;
  final top = (size - box) / 2;

  // 月牙 = 大圆 − 右上方偏移的小圆
  final moonCenter = Offset(left + box * 0.46, top + box * 0.52);
  final moonRadius = box * 0.30;
  final biteCenter = Offset(
    moonCenter.dx + moonRadius * 0.52,
    moonCenter.dy - moonRadius * 0.30,
  );

  final moon = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: moonCenter, radius: moonRadius)),
    Path()
      ..addOval(Rect.fromCircle(center: biteCenter, radius: moonRadius * 0.92)),
  );
  canvas.drawPath(moon, Paint()..color = Colors.white);

  // 周期点：月牙外侧的一颗小圆（"周期里的一个节点"）
  canvas.drawCircle(
    Offset(left + box * 0.74, top + box * 0.30),
    box * 0.072,
    Paint()..color = Colors.white.withValues(alpha: 0.95),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.round(), size.round());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
