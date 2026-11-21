// test/weight_loss/today_widget_test.dart
//
// P3-3「桌面小组件」——**静态验证**口径（用户已确认：本环境无法起模拟器，
// 真机预览/布局效果留待真机验收）。能锁进测试的三层：
//   1) 纯函数：数值 → 小组件显示文本的格式化（key 与 Kotlin 端一致）
//   2) collect：内存库跑通 DB → 显示文本链路（今天口径/预算/体重）
//   3) 原生装配文件存在且互相引用（Kotlin / layout / appwidget-provider / manifest）
//
// 平台通道（HomeWidget.saveWidgetData / updateWidget）只在真机生效，
// 属于真机验收项，不在本文件断言。

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';
import 'package:cycle_note/features/weight_loss/services/today_widget_service.dart';
import 'package:cycle_note/features/weight_loss/services/tdee_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TodayWidgetData（纯函数）', () {
    test('key 从 v1 锁死，与 Kotlin HomeWidgetProvider 同名', () {
      final keys = TodayWidgetData(
        intakeKcal: 1234,
        budgetKcal: 1548,
        weightKg: 55.75,
      ).toWidgetStrings().keys.toSet();

      // Kotlin 端 sp.getString 用的正是这三个 key
      expect(keys, {'widget_intake', 'widget_budget', 'widget_weight'});
    });

    test('数值格式化：摄入取整、预算取整、体重保留一位', () {
      final s = TodayWidgetData(
        intakeKcal: 1234.4,
        budgetKcal: 1548.6,
        weightKg: 55.75,
      ).toWidgetStrings();
      expect(s['widget_intake'], '1234');
      expect(s['widget_budget'], '1549');
      expect(s['widget_weight'], '55.8kg');
    });

    test('档案未填 → 预算 "—"；无体重 → "未记录"', () {
      final s = TodayWidgetData(
        intakeKcal: 0,
        budgetKcal: null,
        weightKg: null,
      ).toWidgetStrings();
      expect(s['widget_budget'], '—');
      expect(s['widget_weight'], '未记录');
      expect(s['widget_intake'], '0');
    });
  });

  group('collect（DB → 数据链路）', () {
    late AppDatabase db;
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });
    tearDown(() async {
      await db.close();
    });

    test('只算今天的摄入；昨日记录不算', () async {
      final now = DateTime.now();
      await db.into(db.mealLogs).insert(
            MealLogsCompanion.insert(
              recordedAt: now.subtract(const Duration(minutes: 5)),
              mealType: 'lunch',
              foodCode: 'chicken_breast',
              foodName: '鸡胸肉',
              grams: 150,
              kcal: 200,
            ),
          );
      await db.into(db.mealLogs).insert(
            MealLogsCompanion.insert(
              recordedAt: now.subtract(const Duration(days: 1)),
              mealType: 'dinner',
              foodCode: 'rice',
              foodName: '米饭',
              grams: 200,
              kcal: 232,
            ),
          );

      final data = await const TodayWidgetService().collect(db);
      expect(data.intakeKcal, 200);
    });

    test('最新体重进数据；档案未填 → 预算 null', () async {
      final now = DateTime.now();
      await db.into(db.weightLogs).insert(
            WeightLogsCompanion.insert(
              recordedAt: now.subtract(const Duration(days: 2)),
              weightKg: 56.0,
            ),
          );
      await db.into(db.weightLogs).insert(
            WeightLogsCompanion.insert(
              recordedAt: now,
              weightKg: 55.75,
            ),
          );

      final data = await const TodayWidgetService().collect(db);
      expect(data.weightKg, 55.75);
      expect(data.budgetKcal, isNull);
    });

    test('有档案 → 预算可算（正数）', () async {
      await db.into(db.bodyProfiles).insertOnConflictUpdate(
            BodyProfilesCompanion.insert(
              id: const Value(1),
              sex: 'female',
              age: 28,
              heightCm: 162,
              startWeightKg: 62,
              activityLevel: 'sedentary',
            ),
          );

      final data = await const TodayWidgetService().collect(db);
      // TdeeService 对该档案的最小安全下限是 1200（女），预算必然为正
      expect(data.budgetKcal, greaterThanOrEqualTo(1200));
      expect(
        data.budgetKcal,
        lessThanOrEqualTo(const TdeeService().calculate(
          const UserProfile(
            sex: Sex.female,
            age: 28,
            heightCm: 162,
            weightKg: 62,
            activity: ActivityLevel.sedentary,
          ),
        ).intakeTarget),
      );
    });
  });

  group('原生装配文件（静态验证）', () {
    test('Kotlin provider / 布局 / appwidget-info / manifest 接线齐全', () {
      final root = Directory.current.path;
      final files = <String, List<String>>{
        'android/app/src/main/kotlin/com/example/cycle_note/HomeWidgetProvider.kt':
            ['HomeWidgetPreferences', 'widget_intake', 'R.layout.widget_today'],
        'android/app/src/main/res/layout/widget_today.xml':
            ['widget_intake', 'widget_budget', 'widget_weight'],
        'android/app/src/main/res/xml/today_widget_info.xml':
            ['@layout/widget_today', '180dp'],
        'android/app/src/main/res/drawable/widget_today_bg.xml': ['corners'],
      };
      files.forEach((relPath, contains) {
        final f = File('$root/$relPath');
        expect(f.existsSync(), isTrue, reason: '缺文件：$relPath');
        final text = f.readAsStringSync();
        for (final c in contains) {
          expect(text.contains(c), isTrue, reason: '$relPath 缺 "$c"');
        }
      });

      final manifest = File(
        '$root/android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest.contains('.HomeWidgetProvider'), isTrue,
          reason: 'manifest 没注册小组件 receiver');
      expect(manifest.contains('@xml/today_widget_info'), isTrue,
          reason: 'manifest 没挂 appwidget-provider 配置');
      // Kotlin 包名必须与 applicationId/namespace 一致
      final kotlin = File(
        '$root/android/app/src/main/kotlin/com/example/cycle_note/HomeWidgetProvider.kt',
      ).readAsStringSync();
      expect(kotlin.contains('package com.example.cycle_note'), isTrue);
    });
  });
}
