// lib/features/me/pages/me_page.dart
//
// 「我的」—— 身体档案、外观、关于。
//
// 这一页承担一个额外职责：**把减脂模块的入口做成有状态的**。
// 没填档案时明确写「还没填」，填了就直接显示「165 cm · 55.0 kg · 每日 1500 kcal」，
// 用户不用点进去才知道自己算出来是多少。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_tokens.dart';
import '../../weight_loss/data/weight_loss_repository.dart'
    show DailyEnergySummary;
import '../../weight_loss/models/weight_loss_models.dart';
import '../../weight_loss/providers/weight_loss_providers.dart';

class MePage extends ConsumerWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final budget = ref.watch(calorieBudgetProvider).valueOrNull;
    final energy = ref.watch(todayEnergyProvider).valueOrNull;
    final latest = ref.watch(latestWeightProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('我的'), centerTitle: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceS),
        children: [
          ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: const Text('身体档案'),
            subtitle: Text(_profileSubtitle(profile, budget)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/body-profile'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.directions_run),
            title: const Text('运动记录'),
            subtitle: Text(_exerciseSubtitle(energy)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/exercise'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.auto_awesome_outlined),
            title: const Text('7 天餐单'),
            subtitle: const Text('按你的预算排好的一周吃什么'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/meal-plan'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restaurant_outlined),
            title: const Text('饮食记录'),
            subtitle: Text(_foodSubtitle(energy)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/food'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: const Text('体重趋势'),
            subtitle: Text(latest == null ? '记一次体重，开始看趋势' : '最新 ${latest.toStringAsFixed(1)} kg'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/weight'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('外观'),
            subtitle: Text(_labelOf(mode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickThemeMode(context, ref, mode),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('每日提醒'),
            subtitle: const Text('每天固定时间提醒记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/reminder'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.ios_share),
            title: const Text('导出数据'),
            subtitle: const Text('体重 / 运动 / 饮食 → CSV（Excel 可读）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/export'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('免责声明 · 数据来源 · 版本'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/me/data-sources'),
          ),
        ],
      ),
    );
  }

  /// 档案摘要。没填档案时给一句"去哪儿点"，而不是空白。
  static String _profileSubtitle(UserProfile? p, CalorieBudget? b) {
    if (p == null) return '还没填，点这里填身高体重';
    final parts = <String>[
      '${p.heightCm.toStringAsFixed(0)} cm',
      '${p.weightKg.toStringAsFixed(1)} kg',
      p.effectiveGoal.label,
    ];
    if (b != null) {
      parts.add('每日 ${b.intakeTarget.round()} kcal');
    }
    return parts.join(' · ');
  }

  static String _foodSubtitle(DailyEnergySummary? e) {
    if (e == null || e.intakeKcal <= 0) return '今天还没记录';
    return '今天已摄入 ${e.intakeKcal.round()} kcal';
  }

  /// 运动摘要。今日消耗直接写出来，让用户不用进页面就能判断"今天动了没"。
  static String _exerciseSubtitle(DailyEnergySummary? e) {
    if (e == null) return '记录一次走路也算';
    if (e.burnKcal <= 0) return '今天还没记录';
    return '今天已消耗 ${e.burnKcal.round()} kcal';
  }

  static String _labelOf(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
      case ThemeMode.system:
        return '跟随系统';
    }
  }

  Future<void> _pickThemeMode(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
  ) async {
    final picked = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('外观'),
        children: [
          for (final m in ThemeMode.values)
            ListTile(
              title: Text(_labelOf(m)),
              trailing: m == current
                  ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                  : null,
              onTap: () => Navigator.of(ctx).pop(m),
            ),
        ],
      ),
    );
    if (picked != null) {
      await ref.read(themeModeProvider.notifier).set(picked);
    }
  }
}
