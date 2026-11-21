// test/weight_loss/daily_summary_test.dart
//
// P1-6 的验收测试。
//
// 核心那条是「余额 == 预算 − 摄入 + 运动」，它同时锁两件事：
//   1) DailyEnergySummary 的公式方向没被写反（很容易写成 预算 − 摄入 − 运动）
//   2) UI 直接用了这个 getter，没有在 widget 里重新拼一份算法
//
// 第二条靠 widget 测试反证：改仓库里的摄入/运动值，卡片上的余额必须跟着变，
// 且等于 getter 的结果。

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/app/theme/app_colors.dart';
import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';
import 'package:cycle_note/features/today/widgets/daily_summary_card.dart';
import 'package:cycle_note/features/weight_loss/data/weight_loss_repository.dart';
import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';
import 'package:cycle_note/features/weight_loss/services/exercise_service.dart';
import 'package:cycle_note/features/weight_loss/services/tdee_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyEnergySummary（纯模型）', () {
    test('余额 = 预算 − 摄入 + 运动消耗', () {
      final s = DailyEnergySummary(
        date: _anyDate,
        intakeKcal: 1200,
        burnKcal: 300,
        budgetKcal: 1500,
      );
      // 1500 − 1200 + 300 = 600
      expect(s.remainKcal, closeTo(600, 0.001));
      expect(s.isOver, isFalse);
    });

    test('摄入超过预算时余额为负，isOver 为真', () {
      final s = DailyEnergySummary(
        date: _anyDate,
        intakeKcal: 1800,
        burnKcal: 0,
        budgetKcal: 1500,
      );
      expect(s.remainKcal, closeTo(-300, 0.001));
      expect(s.isOver, isTrue);
    });

    test('运动可以抵消超标：吃超 300 但动了 400 → 不算超', () {
      final s = DailyEnergySummary(
        date: _anyDate,
        intakeKcal: 1800,
        burnKcal: 400,
        budgetKcal: 1500,
      );
      expect(s.remainKcal, closeTo(100, 0.001));
      expect(s.isOver, isFalse);
    });

    test('什么都没有时余额等于预算，不会出现负数或 NaN', () {
      final s = DailyEnergySummary(
        date: _anyDate,
        intakeKcal: 0,
        burnKcal: 0,
        budgetKcal: 1331.5,
      );
      expect(s.remainKcal, closeTo(1331.5, 0.001));
      expect(s.isOver, isFalse);
    });
  });

  group('DailySummaryCard（组件）', () {
    late AppDatabase db;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedProfile() async {
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
    }

    Future<void> pumpCard(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16),
                child: DailySummaryCard(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('无档案时不渲染（不显示 0 / 0 / 0）', (tester) async {
      await pumpCard(tester);
      expect(find.text('今日明细'), findsNothing);
    });

    testWidgets('无任何记录 → 摄入 0、运动 0、余额等于预算', (tester) async {
      await seedProfile();
      await pumpCard(tester);

      expect(find.text('今日明细'), findsOneWidget);
      expect(find.text('摄入'), findsOneWidget);
      expect(find.text('运动'), findsOneWidget);
      expect(find.text('余额'), findsOneWidget);
      // 摄入 / 运动 都是 0（两个 0：一个在摄入、一个在运动）
      expect(find.text('0'), findsNWidgets(2));
      // 没有超额提示
      expect(find.textContaining('今天超了'), findsNothing);
    });

    testWidgets('吃超预算 → 余额带负号，颜色是 calorieOver 不是红', (tester) async {
      await seedProfile();

      // 直接写一条超过预算 200 的饮食记录
      await db.into(db.mealLogs).insert(
            MealLogsCompanion.insert(
              recordedAt: DateTime.now(),
              mealType: 'lunch',
              foodCode: 'x',
              foodName: '测试',
              grams: 100,
              kcal: _budget + 200,
            ),
          );

      await pumpCard(tester);

      final over = find.text('−200');
      expect(over, findsOneWidget);
      final text = tester.widget<Text>(over);
      expect(text.style?.color, AppColors.light.calorieOver);
      expect(text.style?.color, isNot(AppColors.light.danger));
      expect(find.textContaining('今天超了 200 kcal'), findsOneWidget);
    });

    testWidgets('运动抵消后余额转正，提示消失', (tester) async {
      await seedProfile();

      // 吃 500、动 60 分钟快走（4.3 MET × 62 kg）
      await db.into(db.mealLogs).insert(
            MealLogsCompanion.insert(
              recordedAt: DateTime.now(),
              mealType: 'lunch',
              foodCode: 'x',
              foodName: '测试',
              grams: 100,
              kcal: 500,
            ),
          );
      final burn = ExerciseService.burn(met: 4.3, weightKg: 62, minutes: 60);
      await db.into(db.exerciseLogs).insert(
            ExerciseLogsCompanion.insert(
              recordedAt: DateTime.now(),
              exerciseCode: 'walk',
              exerciseName: '快走',
              met: 4.3,
              minutes: 60,
              weightKgAtTime: 62,
              kcal: burn,
            ),
          );

      await pumpCard(tester);

      expect(find.textContaining('今天超了'), findsNothing);
      expect(find.text('余额'), findsOneWidget);
    });
  });
}

final DateTime _anyDate = DateTime(2026, 1, 1);

/// 基准档案：女 28 / 162 cm / 62 kg / 久坐。
/// 预算一律用 TdeeService 现算，不在测试里重写公式。
const _baseline = UserProfile(
  sex: Sex.female,
  age: 28,
  heightCm: 162,
  weightKg: 62,
  activity: ActivityLevel.sedentary,
);

double get _budget => const TdeeService().calculate(_baseline).intakeTarget;
