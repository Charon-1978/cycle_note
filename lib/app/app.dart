// lib/app/app.dart
//
// 根组件。只做三件事：装主题、装路由、跟随主题模式 + 横屏时的内容宽度约束。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// 横屏 / 大屏时内容的最大宽度（dp）。
///
/// 为什么需要它：
///   · 之前靠 AndroidManifest 里 `screenOrientation="portrait"` 锁死竖屏来"避免变形"，
///     结果在 1920×1080 的模拟器（MuMu 默认、平板分屏）上系统把竖屏画面居中显示，
///     左右各留一条黑边 —— 黑边不是 Flutter 画的，是系统给竖屏窗口的留白；
///   · 正确做法是允许横屏 + 给内容一个最大宽度：卡片不会被拉成"横幅"，
///     背景铺满，既没有黑边也没有变形。
const double kMaxContentWidth = 720;

class CycleNoteApp extends ConsumerWidget {
  const CycleNoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: '月记',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      routerConfig: router,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final size = MediaQuery.sizeOf(context);
        // 竖屏（手机日常姿态）保持原样，不加任何包装 —— 避免给现有布局引入偏移。
        if (size.width <= size.height) return child;
        final bg = Theme.of(context).scaffoldBackgroundColor;
        return ColoredBox(
          color: bg,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              // 让内部的 Scaffold 重新拿到"约束后的宽度"，横屏时卡片不会被拉伸
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(
                    size.width > kMaxContentWidth
                        ? kMaxContentWidth
                        : size.width,
                    size.height,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
