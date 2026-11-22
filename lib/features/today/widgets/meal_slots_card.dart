// lib/features/today/widgets/meal_slots_card.dart
//
// 今日四餐卡（视觉升级新增）。
//
// 为什么今日页必须直接看到"四餐"：
//   热量环只说"还剩多少"，但用户紧接着的问题是"哪一顿还没记/记了多少"。
//   在饮食页里翻四段才能回答，主页就没有"记录闭环"的感觉了。
//
// 约束：
//   · 只读 todayMealLogsProvider，不在这里查库（AGENTS.md §3）
//   · 点击任一餐次都走 recordMealFlow，与饮食页 FAB 同一条流程
//   · 空餐次也显示（"没记"≠"没吃"，与饮食页口径一致）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/surface/soft_card.dart';
import '../../weight_loss/pages/food_log_page.dart' show recordMealFlow;
import '../../weight_loss/providers/weight_loss_providers.dart';
import '../../weight_loss/widgets/food_picker.dart' show kMealLabels;

class MealSlotsCard extends ConsumerWidget {
  const MealSlotsCard({super.key});

  static const _icons = <String, IconData>{
    'breakfast': Icons.free_breakfast_outlined,
    'lunch': Icons.lunch_dining_outlined,
    'dinner': Icons.dinner_dining_outlined,
    'snack': Icons.cookie_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(todayMealLogsProvider).valueOrNull ?? const [];
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;

    final total = logs.fold<double>(0, (sum, l) => sum + l.kcal);

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.spaceL,
        AppTokens.spaceL,
        AppTokens.spaceL,
        AppTokens.spaceS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('今天吃什么', style: AppTokens.title),
              const SizedBox(width: AppTokens.spaceS),
              if (logs.isNotEmpty)
                Text(
                  '${total.round()} kcal',
                  style: AppTokens.caption.copyWith(color: colors.brand),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/me/food'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceS,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('全部'),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spaceXs),
          for (final entry in kMealLabels.entries)
            _MealRow(
              icon: _icons[entry.key] ?? Icons.restaurant_outlined,
              label: entry.value,
              count: logs.where((l) => l.mealType == entry.key).length,
              kcal: logs
                  .where((l) => l.mealType == entry.key)
                  .fold<double>(0, (sum, l) => sum + l.kcal),
              onTap: () => recordMealFlow(context, ref, mealType: entry.key),
            ),
          const SizedBox(height: AppTokens.spaceS),
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_outlined,
                size: 14,
                color: scheme.onSurface.withAlpha(110),
              ),
              const SizedBox(width: AppTokens.spaceXs),
              Expanded(
                child: Text(
                  '点任一餐次就能记一笔，按份/按克都行',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(110),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.kcal,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final double kcal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.colors;
    final empty = count == 0;

    return InkWell(
      onTap: onTap,
      borderRadius: AppTokens.borderM,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceS),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (empty ? scheme.onSurface : colors.brand).withAlpha(
                  empty ? 12 : 22,
                ),
                borderRadius: AppTokens.borderM,
              ),
              child: Icon(
                icon,
                size: 19,
                color: empty ? scheme.onSurface.withAlpha(120) : colors.brand,
              ),
            ),
            const SizedBox(width: AppTokens.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTokens.title.copyWith(
                      color: empty
                          ? scheme.onSurface.withAlpha(170)
                          : scheme.onSurface,
                    ),
                  ),
                  Text(
                    empty ? '还没记' : '$count 条 · ${kcal.round()} kcal',
                    style: AppTokens.caption.copyWith(
                      color: scheme.onSurface.withAlpha(empty ? 100 : 140),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: colors.brand.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 16, color: colors.brand),
            ),
          ],
        ),
      ),
    );
  }
}
