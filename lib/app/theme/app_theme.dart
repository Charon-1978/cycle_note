// lib/app/theme/app_theme.dart
//
// 主题组装：把设计令牌与语义色挂到 ThemeData 上。
//
// 关键点（INTEGRATION.md §2.1）：
//   extensions 里**只能放一套** AppColors —— 浅色主题放 light、深色主题放 dark。
//   两套都放会互相覆盖，且 lerp 会得到意外的中间色。

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// 品牌种子色。取自经期语义色，保证品牌与业务语义同源。
const Color kSeedColor = Color(0xFFE4586F);

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kSeedColor),
    textTheme: AppTokens.toTextTheme(),
    extensions: const <ThemeExtension<dynamic>>[AppColors.light],
    splashFactory: InkSparkle.splashFactory,
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kSeedColor,
      brightness: Brightness.dark,
    ),
    textTheme: AppTokens.toTextTheme(),
    extensions: const <ThemeExtension<dynamic>>[AppColors.dark],
    splashFactory: InkSparkle.splashFactory,
  );
}
