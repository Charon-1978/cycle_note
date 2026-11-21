// lib/main.dart
//
// 启动流程：
//   1) 绑定 WidgetsBinding
//   2) 安装本地错误捕获（P0-7）—— 必须在 runApp 之前
//   3) 预热 SharedPreferences，注入 ProviderScope
//   4) 启动 App

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/error/error_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // P0-7：异常不再白屏，且只写本地日志，不上报任何数据
  await ErrorHandler.install();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const CycleNoteApp(),
    ),
  );
}
