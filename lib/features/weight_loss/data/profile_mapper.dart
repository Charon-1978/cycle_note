// lib/features/weight_loss/data/profile_mapper.dart
//
// 数据库行 ⇄ 领域模型 的唯一转换口。
//
// 为什么单独一层：
//   1) 表里存的是字符串（'male' / 'sedentary' / 'lose'），一旦以后枚举改名，
//      解析会直接抛异常把页面整页打崩。这里统一做**容错解析**——
//      认不出的值退回默认档，而不是 crash。
//   2) 领域模型是 const 值对象，不允许依赖 drift 类型。UI / 服务层只认领域模型，
//      换存储（比如以后上云同步）不需要动 UI。

import 'package:drift/drift.dart' show Value;

import '../../../data/local/database/app_database.dart';
import '../models/weight_loss_models.dart';

/// 安全枚举解析：认不出就退默认值。
///
/// 用 `values.firstWhere` 而不是 `byName`，因为 `byName` 找不到会抛
/// ArgumentError —— 一条脏数据不该让整个档案页打不开。
T _enumOr<T extends Enum>(List<T> values, String? raw, T fallback) {
  if (raw == null || raw.isEmpty) return fallback;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}

extension BodyProfileX on BodyProfile {
  /// 转领域模型。
  ///
  /// [currentWeightKg] 传「最新体重」；为空时退回档案里的起始体重。
  /// 之所以不直接把 latestWeight 塞进表里：档案是「用户填的信息」，
  /// 体重是「随时间变化的记录」，两者混在一起会导致改档案时覆盖掉真实体重。
  UserProfile toDomain({double? currentWeightKg}) {
    return UserProfile(
      sex: _enumOr(Sex.values, sex, Sex.female),
      age: age,
      heightCm: heightCm,
      weightKg: currentWeightKg ?? startWeightKg,
      activity: _enumOr(ActivityLevel.values, activityLevel, ActivityLevel.light),
      goal: _enumOr(WeightGoal.values, goal, WeightGoal.lose),
      pace: _enumOr(LossPace.values, pace, LossPace.standard),
      targetWeightKg: targetWeightKg,
      // 体脂率不在 BodyProfiles 表里（表还没这一列），
      // 预留字段：加列后在这里读，TdeeService 自动切 Katch-McArdle。
      bodyFatPercent: null,
    );
  }
}

extension UserProfileX on UserProfile {
  /// 反向：写库前取出需要落表的字段（体重单独进 WeightLogs）。
  BodyProfilesCompanion toCompanion({
    required double startWeightKg,
    DateTime? updatedAt,
  }) {
    return BodyProfilesCompanion.insert(
      id: const Value(1),
      sex: sex.name,
      age: age,
      heightCm: heightCm,
      startWeightKg: startWeightKg,
      activityLevel: activity.name,
      targetWeightKg: Value(targetWeightKg),
      goal: Value(goal.name),
      pace: Value(pace.name),
      updatedAt: Value(updatedAt ?? DateTime.now()),
    );
  }
}
