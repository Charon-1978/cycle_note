// test/weight_loss/body_profile_page_test.dart
//
// P1-2 的验收测试。只测「用户能感知到的行为」，不测私有实现：
//   1) 首次进入用默认值就能看到预算（不能是空白页 / 0 kcal）
//   2) 改体重，建议摄入立刻变（边填边算）
//   3) 保存后档案落库，并且**同步写一条体重记录**
//      —— 这条最关键：漏了它，趋势页永远看不到用户手填的体重
//   4) 已越过目标体重时自动按「维持」算，不给热量缺口

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/data/local/database/database_provider.dart';
import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';
import 'package:cycle_note/features/weight_loss/pages/body_profile_page.dart';
import 'package:cycle_note/features/weight_loss/services/tdee_service.dart';

/// 与页面里的展示一致：四舍五入取整。
String _kcal(double v) => v.round().toString();

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

  Future<void> pumpPage(WidgetTester tester) async {
    // 页面很长，把测试画布放大，避免 ListView 懒加载导致元素找不到
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: BodyProfilePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 第 0/1/2/3 个输入框分别是 年龄 / 身高 / 体重 / 目标体重
  Finder fieldAt(int index) => find.byType(TextField).at(index);

  testWidgets('首次进入有默认值，且直接算出预算', (tester) async {
    await pumpPage(tester);

    // 默认 25 岁 / 165 cm / 55 kg / 女 / 轻度活动 / 减脂 标准
    const defaultProfile = UserProfile(
      sex: Sex.female,
      age: 25,
      heightCm: 165,
      weightKg: 55,
      activity: ActivityLevel.light,
    );
    final expected = const TdeeService().calculate(defaultProfile);

    expect(find.text(_kcal(expected.intakeTarget)), findsOneWidget);
    expect(find.text('${expected.bmr.round()} kcal'), findsOneWidget);
    expect(find.text('${expected.tdee.round()} kcal'), findsOneWidget);
  });

  testWidgets('改体重后建议摄入立刻变化（不用点保存）', (tester) async {
    await pumpPage(tester);

    const before = UserProfile(
      sex: Sex.female,
      age: 25,
      heightCm: 165,
      weightKg: 55,
      activity: ActivityLevel.light,
    );
    const after = UserProfile(
      sex: Sex.female,
      age: 25,
      heightCm: 165,
      weightKg: 70,
      activity: ActivityLevel.light,
    );

    final beforeKcal = _kcal(const TdeeService().calculate(before).intakeTarget);
    final afterKcal = _kcal(const TdeeService().calculate(after).intakeTarget);
    expect(beforeKcal, isNot(afterKcal), reason: '前提：两种体重的预算必须不同');

    expect(find.text(beforeKcal), findsOneWidget);

    await tester.enterText(fieldAt(2), '70');
    await tester.pumpAndSettle();

    expect(find.text(afterKcal), findsOneWidget);
    expect(find.text(beforeKcal), findsNothing);
  });

  testWidgets('保存后档案落库，并同步写入一条体重记录', (tester) async {
    await pumpPage(tester);

    await tester.enterText(fieldAt(0), '31');
    await tester.enterText(fieldAt(1), '172');
    await tester.enterText(fieldAt(2), '68.5');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '保存'));
    await tester.pumpAndSettle();

    final profiles = await db.select(db.bodyProfiles).get();
    expect(profiles, hasLength(1));
    expect(profiles.single.age, 31);
    expect(profiles.single.heightCm, 172);
    expect(profiles.single.startWeightKg, 68.5);

    final weights = await db.select(db.weightLogs).get();
    expect(weights, hasLength(1), reason: '手填体重也要进 WeightLogs，否则趋势页看不到');
    expect(weights.single.weightKg, 68.5);
  });

  testWidgets('体重已低于目标体重时按「维持」算，缺口为 0', (tester) async {
    await pumpPage(tester);

    // 目标体重 70，当前 55 → 已经「减过了」，应降级为维持
    await tester.enterText(fieldAt(3), '70');
    await tester.pumpAndSettle();

    expect(find.text('每日热量缺口'), findsNothing);
    expect(find.text('热量收支'), findsOneWidget);
    expect(find.text('持平'), findsOneWidget);
    expect(find.text('维持当前体重'), findsOneWidget);
    expect(
      find.textContaining('当前按「维持」计算'),
      findsOneWidget,
      reason: '必须向用户解释为什么没有缺口，否则会以为算错了',
    );
  });
}
