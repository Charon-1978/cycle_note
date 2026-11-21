// test/weight_loss/profile_mapper_test.dart
//
// 这一层的价值只有两点，测试也就只测这两点：
//   1) 脏数据不能让页面崩 —— 枚举认不出必须退默认值，而不是抛 ArgumentError
//   2) 当前体重必须来自 WeightLogs，而不是档案里的 startWeightKg
//      （否则用户改一次身高，累计减重就被清零了）

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:cycle_note/data/local/database/app_database.dart';
import 'package:cycle_note/features/weight_loss/data/profile_mapper.dart';
import 'package:cycle_note/features/weight_loss/models/weight_loss_models.dart';

BodyProfile _row({
  String sex = 'female',
  int age = 28,
  double heightCm = 165,
  double startWeightKg = 60,
  String activityLevel = 'light',
  String goal = 'lose',
  String pace = 'standard',
  double? targetWeightKg,
}) {
  return BodyProfile(
    id: 1,
    sex: sex,
    age: age,
    heightCm: heightCm,
    startWeightKg: startWeightKg,
    activityLevel: activityLevel,
    targetWeightKg: targetWeightKg,
    goal: goal,
    pace: pace,
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('BodyProfile.toDomain', () {
    test('正常值一一对应', () {
      final p = _row(targetWeightKg: 52).toDomain();

      expect(p.sex, Sex.female);
      expect(p.age, 28);
      expect(p.heightCm, 165);
      expect(p.weightKg, 60);
      expect(p.activity, ActivityLevel.light);
      expect(p.goal, WeightGoal.lose);
      expect(p.pace, LossPace.standard);
      expect(p.targetWeightKg, 52);
    });

    test('传了当前体重就覆盖 startWeightKg', () {
      final p = _row(startWeightKg: 60).toDomain(currentWeightKg: 56.4);
      expect(p.weightKg, 56.4, reason: '预算必须按最新体重算，不是建档案那天的体重');
    });

    test('枚举值非法时退默认值，不抛异常', () {
      final p = _row(
        sex: 'unknown_value',
        activityLevel: '',
        goal: 'cut',
        pace: 'extreme',
      ).toDomain();

      expect(p.sex, Sex.female);
      expect(p.activity, ActivityLevel.light);
      expect(p.goal, WeightGoal.lose);
      expect(p.pace, LossPace.standard);
    });

    test('空字符串同样退默认值', () {
      final p = _row(sex: '').toDomain();
      expect(p.sex, Sex.female);
    });

    test('目标体重为空 → null，由 BMI 22 推导', () {
      final p = _row(heightCm: 170).toDomain();
      expect(p.targetWeightKg, isNull);
      // 22 × 1.7² = 63.58
      expect(p.resolvedTargetWeight, closeTo(63.58, 0.01));
    });
  });

  group('UserProfile.toCompanion', () {
    test('显式传入的 startWeightKg 不被当前体重覆盖', () {
      const p = UserProfile(
        sex: Sex.male,
        age: 30,
        heightCm: 175,
        weightKg: 70,
        activity: ActivityLevel.moderate,
        targetWeightKg: 68,
      );

      final c = p.toCompanion(startWeightKg: 82);

      expect(c.startWeightKg.value, 82);
      expect(c.sex.value, 'male');
      expect(c.activityLevel.value, 'moderate');
      expect(c.targetWeightKg.value, 68);
      expect(c.goal.value, 'lose');
      expect(c.id.value, 1, reason: '单行表，主键必须固定为 1');
    });

    test('targetWeightKg 为 null 时写入 null（不是 0）', () {
      const p = UserProfile(
        sex: Sex.female,
        age: 30,
        heightCm: 165,
        weightKg: 60,
        activity: ActivityLevel.light,
      );

      final c = p.toCompanion(startWeightKg: 60);
      expect(c.targetWeightKg, const Value<double?>(null));
    });
  });
}
