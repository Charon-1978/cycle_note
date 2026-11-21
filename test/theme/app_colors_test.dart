// test/theme/app_colors_test.dart
//
// 对应任务卡 P0-4 的验收标准：
//   两套 AppColors 的每个字段都非 null、非全透明，且浅/深色不相等
// 对应 P0-5：深色配色必须与浅色有差异（否则等于没做深色模式）

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/app/theme/app_colors.dart';

void main() {
  group('AppColors 完整性', () {
    test('浅色：11 个语义色全部已定义', () {
      expect(AppColors.light.all.length, 11);
      for (final c in AppColors.light.all) {
        expect(c, isNotNull);
      }
    });

    test('深色：11 个语义色全部已定义', () {
      expect(AppColors.dark.all.length, 11);
      for (final c in AppColors.dark.all) {
        expect(c, isNotNull);
      }
    });

    test('任何一色都不是完全透明（track/grid 允许半透明但不得为 0）', () {
      for (final c in [...AppColors.light.all, ...AppColors.dark.all]) {
        expect(c.a, greaterThan(0.0));
      }
    });
  });

  group('语义色约定', () {
    test('danger 不得与 calorieOver 相同（超标不能用红色）', () {
      expect(AppColors.light.calorieOver, isNot(AppColors.light.danger));
      expect(AppColors.dark.calorieOver, isNot(AppColors.dark.danger));
    });

    test('weightUp 不得与 danger 相同（体重上升不能用红色）', () {
      expect(AppColors.light.weightUp, isNot(AppColors.light.danger));
      expect(AppColors.dark.weightUp, isNot(AppColors.dark.danger));
    });

    test('浅色与深色必须不同（否则等于没做深色模式）', () {
      expect(AppColors.light.period, isNot(AppColors.dark.period));
      expect(AppColors.light.calorieOk, isNot(AppColors.dark.calorieOk));
      expect(AppColors.light.weightUp, isNot(AppColors.dark.weightUp));
    });
  });

  group('copyWith / lerp', () {
    test('copyWith 只改指定字段', () {
      final changed = AppColors.light.copyWith(period: const Color(0xFF000000));
      expect(changed.period, const Color(0xFF000000));
      expect(changed.fertile, AppColors.light.fertile);
      expect(changed.danger, AppColors.light.danger);
    });

    test('lerp(null) 返回自身', () {
      final out = AppColors.light.lerp(null, 0.5);
      expect(out.period, AppColors.light.period);
    });

    test('lerp 中间值介于两套之间', () {
      final mid = AppColors.light.lerp(AppColors.dark, 0.5);
      // 只要不是原值即可，具体色值由 Color.lerp 决定
      expect(mid.period, isNot(AppColors.light.period));
      expect(mid.period, isNot(AppColors.dark.period));
    });
  });
}
