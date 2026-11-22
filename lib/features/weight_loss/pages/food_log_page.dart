// lib/features/weight_loss/pages/food_log_page.dart
//
// 饮食记录（P2-3）。
//
// 页面结构按「早 / 午 / 晚 / 加餐」分组，而不是时间流水：
//   用户复盘饮食时的问题是"我晚饭吃了多少"，不是"我 19:42 吃了什么"。
//   空餐次也照常显示标题 —— 空着本身就是信息（"晚饭没记"≠"晚饭没吃"）。
//
// 允许删单条（记错是常态，不能只许加不许删），但删除必须二次确认：
// 这是唯一有破坏性的操作，danger 红色在这里才被允许使用（ADR-3）。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/surface/soft_card.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/database/database_provider.dart';
import '../data/weight_loss_repository.dart' show DailyEnergySummary;
import '../providers/weight_loss_providers.dart';
import '../services/today_widget_service.dart';
import '../widgets/food_picker.dart';

class FoodLogPage extends ConsumerWidget {
  const FoodLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(todayMealLogsProvider);
    final energy = ref.watch(todayEnergyProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('饮食记录')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _record(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('记录'),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceL),
            child: Text('读取失败：$e', textAlign: TextAlign.center),
          ),
        ),
        data: (logs) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.pagePadding,
            AppTokens.spaceM,
            AppTokens.pagePadding,
            96,
          ),
          children: [
            _TotalCard(energy: energy, count: logs.length),
            const SizedBox(height: AppTokens.cardGap),
            for (final meal in kMealLabels.keys)
              _MealSection(mealType: meal, logs: logs),
          ],
        ),
      ),
    );
  }

  Future<void> _record(BuildContext context, WidgetRef ref) =>
      recordMealFlow(context, ref);
}

/// 记饮食的完整流程（选食物 → 定数量 → 落库 → 刷新）。
///
/// 提成顶层函数是因为有两个入口：饮食记录页的 FAB，和今日页的快捷行。
/// 两个入口必须走同一条路，否则一边改了流程另一边不知道。
Future<void> recordMealFlow(
  BuildContext context,
  WidgetRef ref, {
  String? mealType,
}) async {
  final foods = await ref.read(foodLibraryProvider.future);
  if (!context.mounted) return;

  final entry = await showFoodPicker(
    context,
    foods: foods,
    initialMealType: mealType,
  );
  if (entry == null) return;

  await ref.read(weightLossRepositoryProvider).addMeal(
        mealType: entry.mealType,
        food: entry.food,
        grams: entry.grams,
      );
  invalidateWeightLossChain(ref.invalidate);

  // P3-3：记录后同步桌面小组件。平台通道在测试/桌面端会抛，
  // 小组件不是关键路径，失败静默——记录本身已经成功。
  try {
    await const TodayWidgetService()
        .refresh(ref.read(appDatabaseProvider));
  } catch (_) {}

  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content:
            Text('已记录 ${entry.food.name} ${entry.grams.round()} g'),
      ),
    );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.energy, required this.count});

  final DailyEnergySummary? energy;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    final remain = energy?.remainKcal;
    final isOver = remain != null && remain < 0;

    return SoftCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('今日已摄入', style: AppTokens.label.copyWith(
                  color: scheme.onSurface.withAlpha(140),
                )),
                const SizedBox(height: AppTokens.spaceXs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${(energy?.intakeKcal ?? 0).round()}',
                      style: AppTokens.display.copyWith(
                        color: scheme.onSurface,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceXs),
                    Text(
                      'kcal${count == 0 ? '' : ' · $count 笔'}',
                      style: AppTokens.caption.copyWith(
                        color: scheme.onSurface.withAlpha(130),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (remain != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isOver ? '−' : ''}${remain.abs().round()}',
                  style: AppTokens.headline.copyWith(
                    color: isOver ? colors.calorieOver : colors.calorieOk,
                  ),
                ),
                Text(
                  isOver ? '超出 kcal' : '剩余 kcal',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(120),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MealSection extends ConsumerWidget {
  const _MealSection({required this.mealType, required this.logs});

  final String mealType;
  final List<MealLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final mine = logs.where((l) => l.mealType == mealType).toList();
    final total = mine.fold<double>(0, (s, l) => s + l.kcal);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.cardGap),
      child: SoftCard(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.spaceL,
          AppTokens.spaceM,
          AppTokens.spaceL,
          AppTokens.spaceXs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(kMealLabels[mealType] ?? mealType, style: AppTokens.title),
                const Spacer(),
                Text(
                  '${total.round()} kcal',
                  style: AppTokens.caption.copyWith(
                    color: total > 0
                        ? context.colors.brand
                        : scheme.onSurface.withAlpha(140),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceXs),
            if (mine.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTokens.spaceXs),
                child: Text(
                  '没有记录',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(90),
                  ),
                ),
              )
            else
              for (final log in mine)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceXs),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.foodName, style: AppTokens.body),
                          if (log.proteinG > 0 || log.carbG > 0)
                            Text(
                              '蛋白质 ${log.proteinG.toStringAsFixed(1)} g · '
                              '碳水 ${log.carbG.toStringAsFixed(1)} g',
                              style: AppTokens.caption.copyWith(
                                color: scheme.onSurface.withAlpha(120),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${log.grams.toStringAsFixed(0)} g',
                      style: AppTokens.caption.copyWith(
                        color: scheme.onSurface.withAlpha(160),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceM),
                    Text(
                      '${log.kcal.round()}',
                      style: AppTokens.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceXs),
                    _DeleteButton(logId: log.id, foodName: log.foodName),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  const _DeleteButton({required this.logId, required this.foodName});

  final int logId;
  final String foodName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;

    return IconButton(
      visualDensity: VisualDensity.compact,
      icon: Icon(Icons.close, size: 18, color: colors.danger),
      tooltip: '删除',
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('删除这条记录？'),
            content: Text('「$foodName」将从今日饮食中移除。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('删除', style: TextStyle(color: colors.danger)),
              ),
            ],
          ),
        );
        if (ok != true) return;

        await ref.read(weightLossRepositoryProvider).deleteMeal(logId);
        invalidateWeightLossChain(ref.invalidate);
      },
    );
  }
}
