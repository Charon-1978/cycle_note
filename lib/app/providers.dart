// lib/app/providers.dart
//
// 全局 Provider。当前只有主题模式；减脂相关的 Provider 放
// features/weight_loss/providers/ 下，避免这里变成杂物间。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 在 main() 中 override，避免每个用到偏好的地方都 async。
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('必须在 ProviderScope.overrides 中注入');
});

/// 主题模式（浅色 / 深色 / 跟随系统），持久化到 shared_preferences。
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_read(_prefs));

  static const String key = 'theme_mode';
  final SharedPreferences _prefs;

  static ThemeMode _read(SharedPreferences prefs) {
    switch (prefs.getString(key)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(key, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPrefsProvider));
});
