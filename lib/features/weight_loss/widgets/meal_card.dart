// lib/features/weight_loss/widgets/meal_card.dart
//
// 单餐卡片（P2-1）。
//
// 必须显示「本餐目标」和「实际合计」的对比：餐单的价值在于"照着吃能对上预算"，
// 只给食材克数不给热量对账，用户没法建立"我能吃多少"的直觉。
//
// 组件纯展示。克数/热量都是引擎算好的，这里不做任何再计算。

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';
import '../models/weight_loss_models.dart';

class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.mealType,
    required this.entries,
    required this.targetKcal,
    this.onReroll,
    this.dishName,
  });

  /// breakfast / lunch / dinner / snack
  final String mealType;
  final List<MealEntry> entries;

  /// 该餐的热量目标（引擎按比例拆出来的）
  final double targetKcal;

  /// 「换一道」回调；为 null 时不显示按钮（无食材可换的空餐也不该有）。
  final VoidCallback? onReroll;

  /// 菜名（P3-4 离线规则版生成）。为空/null 时不显示这一行。
  /// 只展示文字，卡片不做任何再计算——菜名由页面从同一份 entries 推出，
  /// 换一道后菜名自然跟着变。
  final String? dishName;

  double get _total => entries.fold(0.0, (s, e) => s + e.kcal);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceL),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppTokens.borderM,
        border: Border.all(
          color: scheme.onSurface.withAlpha(20),
          width: AppTokens.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(_label, style: AppTokens.title),
              const Spacer(),
              Text(
                '${_total.round()} / ${targetKcal.round()} kcal',
                style: AppTokens.body.copyWith(
                  color: scheme.onSurface.withAlpha(160),
                ),
              ),
              if (onReroll != null && entries.isNotEmpty) ...[
                const SizedBox(width: AppTokens.spaceS),
                _RerollButton(onPressed: onReroll!),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.spaceS),
          if ((dishName ?? '').isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.restaurant_outlined,
                  size: 14,
                  color: scheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    dishName!,
                    style: AppTokens.body.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceS),
          ],
          if (entries.isEmpty)
            Text(
              '这一餐没有可推荐的内容',
              style: AppTokens.body.copyWith(
                color: scheme.onSurface.withAlpha(120),
              ),
            )
          else
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTokens.spaceXs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(e.food.name, style: AppTokens.body),
                    ),
                    Text(
                      '${e.grams.toStringAsFixed(0)} g',
                      style: AppTokens.body.copyWith(
                        color: scheme.onSurface.withAlpha(160),
                      ),
                    ),
                    const SizedBox(width: AppTokens.spaceM),
                    SizedBox(
                      width: 72,
                      child: Text(
                        '${e.kcal.round()} kcal',
                        textAlign: TextAlign.end,
                        style: AppTokens.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String get _label => const {
        'breakfast': '早餐',
        'lunch': '午餐',
        'dinner': '晚餐',
        'snack': '加餐',
      }[mealType] ?? mealType;
}

/// 「换一道」小按钮。用紧凑的文本按钮而不是 IconButton：
/// 卡片头部已经很挤，完整图标按钮的命中区会挤掉热量对账文本。
class _RerollButton extends StatelessWidget {
  const _RerollButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 14, color: scheme.primary),
            const SizedBox(width: 2),
            Text(
              '换一道',
              style: AppTokens.caption.copyWith(color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
