// lib/app/app.dart
//
// 根组件。只做三件事：装主题、装路由、跟随主题模式。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

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
    );
  }
}
