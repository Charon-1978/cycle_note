// test/weight_loss/calorie_ring_card_test.dart
//
// P1-3 的验收测试。四个断点都来自手册，逐条对应：
//   1) 女 28/162/62/久坐 → 中心显示的剩余与 TdeeService 一致（同一份算法）
//   2) 无档案 → EmptyState + 按钮，不显示 0 kcal
//   3) isFloored → 出现"已按安全下限调整"说明
//   4) 超预算 → 文案变"已超"，且颜色是 calorieOver（橙）而不是红（ADR-3）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/app/theme/app_colors.dart';
import 'package:cycle_note/app/theme/app_theme.dart';
import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';
import 'package:cycle_note/features/today/widgets/calorie_ring_card.dart';
import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';
import 'package:cycle_note/features/weight_loss/services/tdee_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';

/// 手册基准档案：女 28 岁 / 162 cm / 62 kg / 久坐
const _baseline = UserProfile(
  sex: Sex.female,
  age: 28,
  heightCm: 162,
  weightKg: 62,
  activity: ActivityLevel.sedentary,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  /// 直接塞一条饮食记录，用来构造"超预算"场景
  Future<void> seedMeal(double kcal) async {
    await db.into(db.mealLogs).insert(
          MealLogsCompanion.insert(
            recordedAt: DateTime.now(),
            mealType: 'lunch',
            foodCode: 'test',
            foodName: '测试餐',
            grams: 100,
            kcal: kcal,
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
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: CalorieRingCard(onTapEmptyAction: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('无档案 → 空态 + 引导按钮，不出现 0 kcal', (tester) async {
    await pumpCard(tester);

    expect(find.text('还没算你的每日热量'), findsOneWidget);
    expect(find.text('去填身体档案'), findsOneWidget);
    expect(find.text('剩余 kcal'), findsNothing);
  });

  testWidgets('有档案 → 中心剩余与 TdeeService 一致', (tester) async {
    await seedProfile();
    // 先吃 300 kcal，让"剩余"和"预算"是两个不同的数字，
    // 否则两者取整后相同，断言会分不清谁是谁
    await seedMeal(300);
    await pumpCard(tester);

    final budget = const TdeeService().calculate(_baseline);
    final remain = (budget.intakeTarget - 300).round().toString();

    expect(find.text(remain), findsOneWidget);
    expect(find.text('剩余 kcal'), findsOneWidget);
    // 明细（预算/摄入/运动/余额）由 DailySummaryCard 负责，环里不再重复，
    // 因此这里断言环里**没有**这些字样，防止两条路径又长出两份数字。
    expect(find.text('预算'), findsNothing);
  });

  testWidgets('触发安全下限 → 出现说明文案', (tester) async {
    await seedProfile();
    await pumpCard(tester);

    final budget = const TdeeService().calculate(_baseline);
    expect(budget.isFloored, isTrue, reason: '基准档案必须触发下限');

    expect(
      find.textContaining('已按安全下限调整'),
      findsOneWidget,
      reason: '下限是静默改数字，不解释用户会以为算错了',
    );
    expect(
      find.textContaining('${budget.bmr.round()} kcal'),
      findsOneWidget,
    );
  });

  testWidgets('超预算 → 文案变「已超」，颜色为 calorieOver 而非红', (tester) async {
    await seedProfile();
    final budget = const TdeeService().calculate(_baseline);
    await seedMeal(budget.intakeTarget + 200); // 明确超 200

    await pumpCard(tester);

    expect(find.text('已超 kcal'), findsOneWidget);
    expect(find.text('剩余 kcal'), findsNothing);
    expect(find.text('200'), findsOneWidget);

    // ADR-3：环上的主色必须是 calorieOver，绝不是 danger
    final over = tester.widget<Text>(
      find.text('200'),
    );
    expect(over.style?.color, AppColors.light.calorieOver);
    expect(over.style?.color, isNot(AppColors.light.danger));
  });
}
