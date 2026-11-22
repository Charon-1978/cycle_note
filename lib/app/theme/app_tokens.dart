// lib/app/theme/app_tokens.dart
//
// 设计令牌（Design Tokens）——全项目唯一的间距/圆角/字号/时长来源。
//
// 规则（对应 AGENTS.md R10）：
//   ❌ 业务代码里禁止出现 EdgeInsets.all(16)、SizedBox(height: 12)、fontSize: 14
//   ✅ 一律使用 AppTokens.spaceL / AppTokens.spaceM / AppTokens.body
//
// 为什么要有这一层：
//   月记原本只有 ColorScheme.fromSeed，没有语义层。加入减脂模块后，
//   「经期红」与「热量超标红」会撞色，且间距各页面各自为政。
//   令牌化之后，改一次全局生效，也让 AI 无法再"随手写个数"。

// 用 material 而非 widgets：TextTheme 定义在 material 层。
import 'package:flutter/material.dart';

/// 间距 / 圆角 / 时长 / 触控尺寸 / 字阶。
///
/// 用 `abstract final class` 而非 `class`：禁止被实例化，也禁止被继承。
abstract final class AppTokens {
  const AppTokens._(); // 防止误 new

  // ---------------- 间距（4pt 网格） ----------------
  static const double spaceXs = 4;
  static const double spaceS = 8;
  static const double spaceM = 12;
  static const double spaceL = 16;
  static const double spaceXl = 24;
  static const double spaceXxl = 32;

  /// 页面左右安全边距。所有一级页面的 body 都应是这个值。
  static const double pagePadding = spaceL;

  /// 卡片之间的纵向间距。
  static const double cardGap = spaceM;

  // ---------------- 圆角 ----------------
  static const double radiusS = 8;
  static const double radiusM = 12;

  /// 卡片圆角。2026-11 视觉升级从 16 调到 20：
  /// 旧页面的卡片都写的是 `AppTokens.borderL`，改这一处等于全站统一，
  /// 不用逐个页面改（也避免为了圆角去动 10 个文件的 diff）。
  static const double radiusL = 20;

  /// 与 radiusL 同值，语义更明确的别名（新代码用这个）。
  static const double radiusXl = 20;

  /// 大容器 / 首屏渐变头 / 底部弹层顶部圆角。
  static const double radiusXxl = 28;

  /// 胶囊（标签、FAB）。
  static const double radiusPill = 999;

  static const BorderRadius borderS = BorderRadius.all(Radius.circular(radiusS));
  static const BorderRadius borderM = BorderRadius.all(Radius.circular(radiusM));
  static const BorderRadius borderL = BorderRadius.all(Radius.circular(radiusL));
  static const BorderRadius borderXl =
      BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderXxl =
      BorderRadius.all(Radius.circular(radiusXxl));
  static const BorderRadius borderPill =
      BorderRadius.all(Radius.circular(radiusPill));

  /// 首屏渐变头只圆下缘。
  static const BorderRadius borderBottomXxl = BorderRadius.vertical(
    bottom: Radius.circular(radiusXxl),
  );

  // ---------------- 阴影 ----------------
  //
  // 只用两档，避免每张卡自己调阴影导致页面脏。
  // 颜色由调用方给（令牌层不持有颜色，R10 的颜色来源只有 AppColors）。
  static List<BoxShadow> shadowSoft(Color color) => [
        BoxShadow(
          color: color,
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> shadowLifted(Color color) => [
        BoxShadow(
          color: color,
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  // ---------------- 动效时长 ----------------
  /// 颜色/透明度切换。
  static const Duration durFast = Duration(milliseconds: 150);

  /// 数值变化、环形进度（对应计划书 §附录 A「数值变化 250ms」）。
  static const Duration durBase = Duration(milliseconds: 250);

  /// 页面转场。禁止超过 400ms。
  static const Duration durPage = Duration(milliseconds: 300);

  static const Curve curve = Curves.easeOutCubic;

  // ---------------- 触控 ----------------
  /// 最小可点击区域（无障碍要求 ≥48dp）。
  static const double minTouchTarget = 48;

  // ---------------- 边框 ----------------
  /// 卡片描边宽度（配合 elevation 0 使用，见附录 A）。
  static const double borderWidth = 1;

  /// 卡片描边透明度。
  static const double borderOpacity = 0.08;

  // ---------------- 字阶 ----------------
  // 全部不设 color，交由 Theme 继承，避免深浅色下写死。
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    height: 22 / 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle title = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
  );

  /// 热量环中心的大数字。
  static const TextStyle display = TextStyle(
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  /// 图表刻度专用（比 caption 更小更淡，颜色由调用方给）。
  static const TextStyle chartAxis = TextStyle(
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w500,
  );

  /// 组装成 TextTheme，供 ThemeData 使用。
  static TextTheme toTextTheme() => const TextTheme(
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: label,
        labelMedium: label,
        labelSmall: caption,
        titleLarge: headline,
        titleMedium: title,
        titleSmall: label,
        displaySmall: display,
        headlineSmall: headline,
      );
}
