// lib/features/weight_loss/services/today_widget_service.dart
//
// 桌面小组件数据同步（P3-3）。
//
// 结构：
//   · buildWidgetData —— 纯函数：把数值格式化成小组件要显示的三行文本；
//   · refresh —— IO：写 SharedPreferences（home_widget）并触发重绘。
//
// 数据流：记录饮食/体重后调用 refresh → Dart 把文本写进
// SharedPreferences("HomeWidgetPreferences") → 原生 HomeWidgetProvider
// （Kotlin）读同一份偏好并 updateAppWidget。**静态验证口径**（用户已确认）：
// 本环境无法起模拟器，真机预览/布局效果留待真机验收，见验收记录。

import 'package:drift/drift.dart';
import 'package:home_widget/home_widget.dart';

import '../../../data/local/database/app_database.dart';
import '../data/profile_mapper.dart';
import 'tdee_service.dart';

/// 小组件显示的数据行（纯文本，供纯函数测试）。
class TodayWidgetData {
  const TodayWidgetData({
    required this.intakeKcal,
    required this.budgetKcal,
    required this.weightKg,
  });

  /// 今日已摄入（未记录 = 0）
  final double intakeKcal;

  /// 每日预算（档案未填 = null → 显示 "—"）
  final double? budgetKcal;

  /// 最新体重（未记录 = null → 显示 "未记录"）
  final double? weightKg;

  /// 生成小组件显示文本。key 从 v1 锁死（Kotlin 端同名读取）。
  Map<String, String> toWidgetStrings() {
    return {
      'widget_intake': intakeKcal.round().toString(),
      'widget_budget': budgetKcal == null ? '—' : budgetKcal!.round().toString(),
      'widget_weight': weightKg == null ? '未记录' : '${weightKg!.toStringAsFixed(1)}kg',
    };
  }
}

/// 小组件数据同步。所有平台通道调用都可能抛 MissingPluginException
/// （测试环境/桌面端），调用方统一 catch。
class TodayWidgetService {
  const TodayWidgetService();

  /// 从库中汇总小组件数据（纯 DB 读取，无平台通道，可测）。
  ///
  /// 这里自己查库而不是从 Provider 拿：记录动作发生在多个页面，
  /// 服务层直接读库能让"记录 → 小组件刷新"不依赖任何页面状态。
  Future<TodayWidgetData> collect(AppDatabase db) async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final dayEnd = day.add(const Duration(days: 1));

    final meals = await (db.select(db.mealLogs)
          ..where((t) =>
              t.recordedAt.isBiggerOrEqualValue(day) &
              t.recordedAt.isSmallerThanValue(dayEnd)))
        .get();
    final intake = meals.fold(0.0, (s, m) => s + m.kcal);

    final weightRow = await (db.select(db.weightLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .getSingleOrNull();

    // 预算：读档案行 → 领域模型 → TDEE。档案没填就显示 "—"，
    // 绝不猜一个预算数字——错预算比没预算更误导。
    double? budget;
    final profileRow =
        await (db.select(db.bodyProfiles)..limit(1)).getSingleOrNull();
    if (profileRow != null) {
      final latestWeight = weightRow?.weightKg;
      final profile = profileRow.toDomain(currentWeightKg: latestWeight);
      budget = const TdeeService().calculate(profile).intakeTarget;
    }

    return TodayWidgetData(
      intakeKcal: intake,
      budgetKcal: budget,
      weightKg: weightRow?.weightKg,
    );
  }

  /// 记录动作（记饮食/记体重）之后调用：重算今日数据并推给小组件。
  Future<void> refresh(AppDatabase db) => collect(db).then(update);

  /// 写数据 + 触发重绘（平台通道）。
  Future<void> update(TodayWidgetData data) async {
    for (final e in data.toWidgetStrings().entries) {
      await HomeWidget.saveWidgetData<String>(e.key, e.value);
    }
    await HomeWidget.updateWidget(
      name: 'HomeWidgetProvider',
      androidName: 'HomeWidgetProvider',
    );
  }
}
