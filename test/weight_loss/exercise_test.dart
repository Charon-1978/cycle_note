// test/weight_loss/exercise_test.dart
//
// P1-5 的验收测试。
//
// 重点不在"能不能记录"，而在**历史不能被重算**：
// 用户半年后重了 10 斤，三个月前那次跑步的消耗不该跟着变。
// 所以 kcal 与 weightKgAtTime 必须是冗余快照，不能 join 当前档案去算。

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/features/weight_loss/data/weight_loss_repository.dart';
import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';
import 'package:cycle_note/features/weight_loss/services/exercise_service.dart';
import 'package:cycle_note/features/weight_loss/widgets/exercise_picker.dart';

const _run = ExerciseDef(code: 'run_8', name: '跑步 8 km/h', met: 8.3);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MET 表与公式', () {
    test('本地 assets 能加载，且项目数够用（≥45）', () async {
      await ExerciseService.instance.load();
      final all = ExerciseService.instance.all;

      expect(all.length, greaterThanOrEqualTo(45));
      // 数据本身要合法：MET 必须为正，否则能耗算出来是 0 或负数
      expect(all.every((e) => e.met > 0), isTrue);
      expect(all.every((e) => e.name.isNotEmpty), isTrue);
    });

    test('搜索能按中文名与 code 命中', () async {
      await ExerciseService.instance.load();
      expect(ExerciseService.instance.search('跑步'), isNotEmpty);
      expect(ExerciseService.instance.search('run').isNotEmpty, isTrue);
      expect(ExerciseService.instance.search('这个词不存在'), isEmpty);
    });

    test('burn = MET × 3.5 × kg / 200 × min（误差 < 0.1）', () {
      // 8.3 × 3.5 × 60 / 200 × 30 = 261.45
      final kcal = ExerciseService.burn(met: 8.3, weightKg: 60, minutes: 30);
      expect(kcal, closeTo(261.45, 0.1));
    });

    test('时长为 0 或体重为 0 时返回 0，不产生 NaN/Infinity', () {
      expect(ExerciseService.burn(met: 8, weightKg: 60, minutes: 0), 0);
      expect(ExerciseService.burn(met: 8, weightKg: 0, minutes: 30), 0);
    });

    test('net=true 时扣除静息那一份（MET−1）', () {
      final gross = ExerciseService.burn(met: 8, weightKg: 70, minutes: 60);
      final net = ExerciseService.burn(
        met: 8,
        weightKg: 70,
        minutes: 60,
        net: true,
      );
      expect(net, lessThan(gross));
      // 比例应为 (8-1)/8
      expect(net / gross, closeTo(7 / 8, 0.0001));
    });
  });

  group('运动记录落库', () {
    late AppDatabase db;
    late WeightLossRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = WeightLossRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('保存时写入当时的体重，之后改档案不影响历史 kcal', () async {
      await repo.addExercise(def: _run, minutes: 30, weightKg: 60);

      final before = (await repo.exerciseLogs()).single;
      expect(before.weightKgAtTime, 60);
      expect(before.kcal, closeTo(261.45, 0.1));

      // 用户变重了，重新保存档案
      await repo.saveProfile(
        const UserProfile(
          sex: Sex.female,
          age: 30,
          heightCm: 165,
          weightKg: 75,
          activity: ActivityLevel.moderate,
        ),
        preserveStartWeight: true,
      );

      final after = (await repo.exerciseLogs()).single;
      expect(after.weightKgAtTime, 60, reason: '历史记录不能被新体重覆盖');
      expect(after.kcal, closeTo(before.kcal, 0.0001), reason: '历史 kcal 不能被重算');
    });

    test('一天可以记多条，按时间倒序返回', () async {
      final now = DateTime.now();
      await repo.addExercise(def: _run, minutes: 20, weightKg: 60, at: now);
      await repo.addExercise(
        def: const ExerciseDef(code: 'walk', name: '快走', met: 4.3),
        minutes: 40,
        weightKg: 60,
        at: now.subtract(const Duration(hours: 3)),
      );

      final logs = await repo.exerciseLogs();
      expect(logs, hasLength(2));
      expect(logs.first.recordedAt.isAfter(logs.last.recordedAt), isTrue);
    });

    test('删除单条：行消失，当日合计随之减少', () async {
      await repo.addExercise(def: _run, minutes: 30, weightKg: 60);
      await repo.addExercise(
        def: const ExerciseDef(code: 'yoga', name: '瑜伽', met: 2.5),
        minutes: 60,
        weightKg: 60,
      );
      final before = await repo.exerciseLogs();
      expect(before, hasLength(2));

      final removed = before.first;
      await repo.deleteExercise(removed.id);

      final after = await repo.exerciseLogs();
      expect(after, hasLength(1));
      expect(after.single.id, isNot(removed.id));

      final budget = const TdeeServiceStub().budget();
      final summary = await repo.summaryOf(DateTime.now(), budget);
      expect(
        summary.burnKcal,
        closeTo(after.single.kcal, 0.01),
        reason: '删掉之后当日消耗只剩剩下那条',
      );
    });

    test('今日汇总里的 burnKcal 等于当天记录之和', () async {
      await repo.addExercise(def: _run, minutes: 30, weightKg: 60);
      await repo.addExercise(
        def: const ExerciseDef(code: 'yoga', name: '瑜伽', met: 2.5),
        minutes: 60,
        weightKg: 60,
      );

      final budget = const TdeeServiceStub().budget();
      final summary = await repo.summaryOf(DateTime.now(), budget);

      final expected = ExerciseService.burn(
            met: 8.3,
            weightKg: 60,
            minutes: 30,
          ) +
          ExerciseService.burn(met: 2.5, weightKg: 60, minutes: 60);
      expect(summary.burnKcal, closeTo(expected, 0.01));
    });
  });

  group('时长校验（弹层）', () {
    testWidgets('0 分钟与 601 分钟都被拦截', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showExercisePicker(
                  context,
                  defs: const [_run],
                  weightKg: 60,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 先选一项运动，把"未选运动"这个禁用原因排除掉
      await tester.tap(find.text('跑步 8 km/h'));
      await tester.pumpAndSettle();

      final minutesField = find.descendant(
        of: find.byType(TextField).last,
        matching: find.byType(EditableText),
      );

      await tester.enterText(minutesField, '0');
      await tester.pumpAndSettle();
      expect(find.textContaining('时长需在 1–600'), findsOneWidget);

      await tester.enterText(minutesField, '601');
      await tester.pumpAndSettle();
      expect(find.textContaining('时长需在 1–600'), findsOneWidget);

      await tester.enterText(minutesField, '45');
      await tester.pumpAndSettle();
      expect(find.textContaining('时长需在'), findsNothing);
      expect(find.textContaining('记 45 分钟'), findsOneWidget);
    });
  });
}

/// 汇总测试只需要一个"够用的"预算对象，不必真算一遍 TDEE。
class TdeeServiceStub {
  const TdeeServiceStub();
  CalorieBudget budget() => const CalorieBudget(
        bmr: 1300,
        tdee: 1600,
        intakeTarget: 1400,
        deficit: 200,
        proteinG: 100,
        fatG: 40,
        carbG: 150,
        isFloored: false,
        bmrFormula: 'test',
      );
}
