// lib/app/theme/app_theme.dart
//
// 主题组装：把设计令牌与语义色挂到 ThemeData 上。
//
// 关键点（INTEGRATION.md §2.1）：
//   extensions 里**只能放一套** AppColors —— 浅色主题放 light、深色主题放 dark。
//   两套都放会互相覆盖，且 lerp 会得到意外的中间色。
//
// 2026-11 视觉升级（个人自用版，参考美柚的「大圆角 + 淡底 + 胶囊」语言）：
//   · 页面底色不再是纯白，而是极淡的品牌色底，让白卡浮起来（浅色 #FFF7F8）
//   · 卡片统一 20 圆角 + 极轻投影，不用 elevation（elevation 会在深色下变灰）
//   · 按钮/标签/开关一律胶囊形，主按钮用品牌渐变
//   · 所有组件样式在这里定义一次，页面里不再写 BoxDecoration 的重复参数

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// 品牌种子色。取自经期语义色，保证品牌与业务语义同源。
const Color kSeedColor = Color(0xFFE4586F);

ThemeData buildLightTheme() => _build(AppColors.light, Brightness.light);

ThemeData buildDarkTheme() => _build(AppColors.dark, Brightness.dark);

ThemeData _build(AppColors colors, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    brightness: brightness,
  ).copyWith(
    // 卡片/弹层用自有表面色，其余沿用 fromSeed 的调和色板
    surface: colors.surface,
    primary: colors.brand,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: AppTokens.toTextTheme(),
    extensions: <ThemeExtension<dynamic>>[colors],
    splashFactory: InkSparkle.splashFactory,
    scaffoldBackgroundColor: colors.pageBg,

    // ---------------- 顶栏 ----------------
    appBarTheme: AppBarTheme(
      backgroundColor: colors.pageBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: AppTokens.headline.copyWith(color: scheme.onSurface),
      iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 22),
    ),

    // ---------------- 卡片 ----------------
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: AppTokens.borderXl),
    ),

    // ---------------- 底部导航 ----------------
    //
    // 中文标签必须常显：图标单独出现时，用户分不清「趋势」和「日历」。
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: colors.brandSoft,
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: AppTokens.borderPill,
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return AppTokens.caption.copyWith(
          color: selected ? colors.brand : scheme.onSurface.withAlpha(140),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? colors.brand : scheme.onSurface.withAlpha(140),
        );
      }),
    ),

    // ---------------- 按钮 ----------------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.brand,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, AppTokens.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceXl),
        textStyle: AppTokens.title,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.borderPill,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        minimumSize: const Size(0, AppTokens.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceL),
        textStyle: AppTokens.label,
        side: BorderSide(color: scheme.onSurface.withAlpha(30)),
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.borderPill,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.brand,
        textStyle: AppTokens.label,
      ),
    ),

    // ---------------- 选择器 ----------------
    chipTheme: ChipThemeData(
      backgroundColor: colors.brandSoft,
      selectedColor: colors.brand,
      side: BorderSide.none,
      labelStyle: AppTokens.label.copyWith(color: scheme.onSurface),
      secondaryLabelStyle: AppTokens.label.copyWith(color: Colors.white),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceM,
        vertical: AppTokens.spaceS,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderPill),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: colors.surface,
        foregroundColor: scheme.onSurface.withAlpha(160),
        selectedBackgroundColor: colors.brand,
        selectedForegroundColor: Colors.white,
        side: BorderSide.none,
        textStyle: AppTokens.label,
        shape: const RoundedRectangleBorder(
          borderRadius: AppTokens.borderPill,
        ),
      ),
    ),

    // ---------------- 列表 ----------------
    listTileTheme: ListTileThemeData(
      iconColor: colors.brand,
      titleTextStyle: AppTokens.title.copyWith(color: scheme.onSurface),
      subtitleTextStyle: AppTokens.caption.copyWith(
        color: scheme.onSurface.withAlpha(140),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceL,
        vertical: AppTokens.spaceXs,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderM),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withAlpha(14),
      thickness: 1,
      space: 1,
    ),

    // ---------------- 输入 ----------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.brandSoft.withAlpha(90),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spaceL,
        vertical: AppTokens.spaceM,
      ),
      hintStyle: AppTokens.body.copyWith(color: scheme.onSurface.withAlpha(110)),
      border: const OutlineInputBorder(
        borderRadius: AppTokens.borderM,
        borderSide: BorderSide.none,
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: AppTokens.borderM,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTokens.borderM,
        borderSide: BorderSide(color: colors.brand, width: 1.5),
      ),
    ),

    // ---------------- 弹层 ----------------
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderXxl),
      titleTextStyle: AppTokens.headline.copyWith(color: scheme.onSurface),
      contentTextStyle: AppTokens.body.copyWith(color: scheme.onSurface),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.radiusXxl),
        ),
      ),
      showDragHandle: true,
      dragHandleColor: scheme.onSurface.withAlpha(40),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: AppTokens.body.copyWith(color: scheme.onInverseSurface),
      shape: const RoundedRectangleBorder(borderRadius: AppTokens.borderM),
      insetPadding: const EdgeInsets.all(AppTokens.spaceL),
    ),

    // ---------------- 其它 ----------------
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : scheme.onSurface.withAlpha(120),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.brand
            : scheme.onSurface.withAlpha(30),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.brand,
      linearTrackColor: colors.track,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.brand,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: AppTokens.borderPill,
      ),
    ),
  );
}
