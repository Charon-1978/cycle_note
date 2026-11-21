// lib/features/weight_loss/pages/meal_plan_page.dart
//
// 餐单页（P2-1 基础 + P2-2 30 天切换 / 换一道）。
//
// 手册验收断言的落地方式：
//   · 「每日偏差 ≤5%」→ 顶部横幅显示引擎自检结果；
//     超过 5% 时显示**明确的黄色提示**，绝不静默降级（手册禁止项）。
//   · 「四餐齐全」→ 每天四张 MealCard，空餐次照常渲染并写明原因。
//   · 「食材库为空 → EmptyState」→ provider 侧返回 null，页面走空态。
//   · 「7/30 天切换 ≤100 ms」→ 两个天数各自独立生成并缓存（provider family），
//     切换只是换引用，不做重算。
//   · 「换一道不改当日总热量 ±3%」→ 换一道走引擎 composeMeal（dayIndex 平移），
//     主食 rebalance 会把本餐收敛回目标，页面只替换该餐内容并重算合计。
//
// 为什么把偏差直接展示给用户：这是"这个餐单可信吗"的唯一证据，
// 藏起来等于让用户盲信一个算出来的数字。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../models/weight_loss_models.dart';
import '../providers/weight_loss_providers.dart';
import '../services/dish_namer.dart';
import '../services/meal_plan_engine.dart';
import '../services/meal_plan_loader.dart';
import '../widgets/date_strip.dart';
import '../widgets/meal_card.dart';

class MealPlanPage extends ConsumerStatefulWidget {
  const MealPlanPage({super.key});

  @override
  ConsumerState<MealPlanPage> createState() => _MealPlanPageState();
}

class _MealPlanPageState extends ConsumerState<MealPlanPage> {
  int _days = 7;
  int _day = 0;

  /// 「换一道」的轮换偏移。key = '$day-$meal'。
  /// 页面持有而非写进计划对象：计划是引擎的确定性产物，改它就得改引擎
  /// 的输出语义；偏移只是"再看一组"的浏览状态，关掉页面重开就回到默认。
  /// composeMeal 本身只算 4 个条目，成本可忽略，不做内容缓存——
  /// 缓存反而会在预算/档案变更后留下脏数据。
  final Map<String, int> _rotationOffsets = {};

  void _reroll(int day, String meal) {
    final key = '$day-$meal';
    setState(() {
      _rotationOffsets[key] = (_rotationOffsets[key] ?? 0) + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(mealPlanProvider(_days));

    return Scaffold(
      appBar: AppBar(title: Text('$_days 天餐单')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceL),
            child: Text('生成失败：$e', textAlign: TextAlign.center),
          ),
        ),
        data: (plan) {
          if (plan == null || plan.days.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.restaurant_menu,
                title: '还没有餐单',
                message: '先填好身体档案，再根据你的预算生成一周吃什么',
                actionLabel: '去填身体档案',
                onAction: () => context.push('/me/body-profile'),
              ),
            );
          }
          // 7 → 30 切换后，旧的选中下标可能越界
          final selected = _day.clamp(0, plan.days.length - 1);
          if (selected != _day) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _day = selected);
            });
          }
          return _Body(
            plan: plan,
            selectedDay: selected,
            days: _days,
            rotationOffsets: _rotationOffsets,
            onDayChanged: (i) => setState(() => _day = i),
            onDaysChanged: (d) => setState(() {
              _days = d;
              _day = _day.clamp(0, d - 1);
            }),
            onReroll: _reroll,
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.plan,
    required this.selectedDay,
    required this.days,
    required this.rotationOffsets,
    required this.onDayChanged,
    required this.onDaysChanged,
    required this.onReroll,
  });

  static const DishNamer _namer = RuleBasedDishNamer();

  final MultiDayPlan plan;
  final int selectedDay;
  final int days;
  final Map<String, int> rotationOffsets;
  final ValueChanged<int> onDayChanged;
  final ValueChanged<int> onDaysChanged;
  final void Function(int day, String meal) onReroll;

  /// 计算某天某餐的最终内容：默认用计划里的，换过一道则用引擎重组的。
  List<MealEntry> _entriesFor(int day, String meal, double targetKcal) {
    final offset = rotationOffsets['$day-$meal'] ?? 0;
    if (offset == 0) return plan.days[day].byMeal(meal);
    return MealPlanLoader.instance.engine.composeMeal(
      meal: meal,
      targetKcal: targetKcal,
      dayIndex: day,
      rotationOffset: offset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    // 换一道之后，每天的合计必须重算（含被替换的餐次），对账不能拿旧数。
    double dayTotal = 0;
    final mealTargets = <String, double>{};
    final mealEntries = <String, List<MealEntry>>{};
    for (final meal in const ['breakfast', 'lunch', 'dinner', 'snack']) {
      final target = _mealTarget(plan, meal);
      final entries = _entriesFor(selectedDay, meal, target);
      mealTargets[meal] = target;
      mealEntries[meal] = entries;
      dayTotal += entries.fold(0.0, (s, e) => s + e.kcal);
    }
    // 未选中但没换过一道的天数，用计划原值兜底不影响本页；
    // 偏差只对"当前正在看的天"计算。

    // 引擎自检：每日偏差百分比。这是给用户看的"可信度"，不是调试信息。
    final deviations = MealPlanEngine.validate(plan);
    final worst = deviations.isEmpty
        ? 0.0
        : deviations.fold<double>(
            0, (m, v) => v.abs() > m.abs() ? v : m);
    final outOfTolerance = worst.abs() > 5;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        0,
        AppTokens.spaceM,
        0,
        AppTokens.spaceXxl,
      ),
      children: [
        // 7 / 30 天切换
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 天')),
              ButtonSegment(value: 30, label: Text('30 天')),
            ],
            selected: {days},
            onSelectionChanged: (s) => onDaysChanged(s.first),
          ),
        ),
        const SizedBox(height: AppTokens.cardGap),

        DateStrip(
          dates: plan.days.map((d) => d.date).toList(),
          selected: selectedDay,
          onChanged: onDayChanged,
        ),
        const SizedBox(height: AppTokens.cardGap),

        // 全天对账
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${dayTotal.round()}',
                style: AppTokens.display.copyWith(color: colors.calorieOk),
              ),
              const SizedBox(width: AppTokens.spaceS),
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.spaceXs),
                child: Text(
                  'kcal / 全天目标 ${plan.budget.intakeTarget.round()}',
                  style: AppTokens.body.copyWith(
                    color: scheme.onSurface.withAlpha(150),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.spaceXs),
                child: Text(
                  '偏差 ${(dayTotal - plan.budget.intakeTarget) >= 0 ? '+' : ''}'
                  '${((dayTotal - plan.budget.intakeTarget) / plan.budget.intakeTarget * 100).toStringAsFixed(1)}%',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spaceS),

        // 自检横幅：正常时轻描淡写，超差时必须显眼且给出解释
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: _ValidationBanner(
            days: days,
            worst: worst,
            outOfTolerance: outOfTolerance,
          ),
        ),
        const SizedBox(height: AppTokens.cardGap),

        // 四餐
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: Column(
            children: [
              for (final meal in const [
                'breakfast',
                'lunch',
                'dinner',
                'snack',
              ]) ...[
                MealCard(
                  mealType: meal,
                  entries: mealEntries[meal]!,
                  targetKcal: mealTargets[meal]!,
                  onReroll: () => onReroll(selectedDay, meal),
                  dishName: _namer.name(mealEntries[meal]!, meal),
                ),
                const SizedBox(height: AppTokens.cardGap),
              ],
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: Text(
            '克数按你的预算反解得出，不用精确到秤；偏差在 ±5% 内都算执行到位。'
            '食材只是参考，同类可以互换（如鸡胸肉换瘦牛肉）；「换一道」不会改变当天总热量。',
            style: AppTokens.caption.copyWith(
              color: scheme.onSurface.withAlpha(140),
            ),
          ),
        ),
      ],
    );
  }

  /// 该餐的热量目标。引擎按 MealSplit.standard 拆分，这里用同一份比例
  /// 反推目标值用于对账——比例是常量，不会和引擎打架。
  double _mealTarget(MultiDayPlan plan, String meal) {
    const s = MealSplit.standard;
    final ratio = switch (meal) {
      'breakfast' => s.breakfast,
      'lunch' => s.lunch,
      'dinner' => s.dinner,
      _ => s.snack,
    };
    return plan.budget.intakeTarget * ratio;
  }
}

class _ValidationBanner extends StatelessWidget {
  const _ValidationBanner({
    required this.days,
    required this.worst,
    required this.outOfTolerance,
  });

  final int days;
  final double worst;
  final bool outOfTolerance;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final color = outOfTolerance ? colors.calorieOver : colors.calorieOk;
    final text = outOfTolerance
        ? '有几天偏差达到 ${worst.abs().toStringAsFixed(1)}%，'
            '超出 ±5% 容差。可能是个别食材克数被上限截断了，建议改一改目标体重或速度后重新生成。'
        : '$days 天最大偏差 ${worst.abs().toStringAsFixed(1)}%，在 ±5% 容差内。';

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceM),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: AppTokens.borderS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            outOfTolerance ? Icons.warning_amber_outlined : Icons.verified_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppTokens.spaceS),
          Expanded(
            child: Text(
              text,
              style: AppTokens.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
