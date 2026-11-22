// lib/features/me/pages/me_page.dart
//
// 「我的」—— 身体档案、外观、关于。
//
// 2026-11 视觉升级：
//   · 顶部渐变头承担"我是谁 / 今天的状态"，下面才是分组菜单；
//   · 菜单从"一条条 ListTile + 分割线"改成"分组卡片 + 圆角色块图标"，
//     一屏能看到全部入口（原来 10 条分割线读完要滑两屏）；
//   · 每条的副标题仍然是**有状态的一句话**：没填档案就写"还没填"，
//     填了直接写"165 cm · 55.0 kg · 每日 1500 kcal"，不用点进去才知道。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/surface/gradient_header.dart';
import '../../../core/widgets/surface/section_header.dart';
import '../../update/update_config.dart';
import '../../../core/widgets/surface/soft_card.dart';
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

    final colors = context.colors;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientHeader(
            child: _ProfileHeader(
              subtitle: _profileSubtitle(profile, budget),
              onTap: () => context.push('/me/body-profile'),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.pagePadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionHeader(title: '记录'),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.spaceXs,
                    ),
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.badge_outlined,
                          tint: colors.brand,
                          title: '身体档案',
                          subtitle: _profileSubtitle(profile, budget),
                          onTap: () => context.push('/me/body-profile'),
                        ),
                        const _Divider(),
                        _MenuTile(
                          icon: Icons.monitor_weight_outlined,
                          tint: colors.brand,
                          title: '体重趋势',
                          subtitle: latest == null
                              ? '记一次体重，开始看趋势'
                              : '最新 ${latest.toStringAsFixed(1)} kg',
                          onTap: () => context.push('/me/weight'),
                        ),
                        const _Divider(),
                        _MenuTile(
                          icon: Icons.restaurant_outlined,
                          tint: colors.calorieOver,
                          title: '饮食记录',
                          subtitle: _foodSubtitle(energy),
                          onTap: () => context.push('/me/food'),
                        ),
                        const _Divider(),
                        _MenuTile(
                          icon: Icons.directions_run,
                          tint: colors.fertile,
                          title: '运动记录',
                          subtitle: _exerciseSubtitle(energy),
                          onTap: () => context.push('/me/exercise'),
                        ),
                        const _Divider(),
                        _MenuTile(
                          icon: Icons.auto_awesome_outlined,
                          tint: colors.ovulation,
                          title: '7 天餐单',
                          subtitle: '按你的预算排好的一周吃什么',
                          onTap: () => context.push('/me/meal-plan'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXl),
                  const SectionHeader(title: '周期'),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.spaceXs,
                    ),
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.history,
                          tint: colors.period,
                          title: '经期历史',
                          subtitle: '全部经期记录 · 平均周期与经期天数',
                          onTap: () => context.push('/period/history'),
                        ),
                        const _Divider(),
                        _MenuTile(
                          icon: Icons.notifications_none,
                          tint: colors.period,
                          title: '每日提醒',
                          subtitle: '每天固定时间提醒记录',
                          onTap: () => context.push('/me/reminder'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXl),
                  const SectionHeader(title: '数据与关于'),
                  SoftCard(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTokens.spaceXs,
                    ),
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.storage_outlined,
                          tint: colors.weightUp,
                          title: '数据管理',
                          subtitle: '导出 / 导入 CSV · 恢复本机备份',
                          onTap: () => context.push('/me/export'),
                        ),
                        const _Divider(),
                        _MenuTile(
                          icon: Icons.palette_outlined,
                          tint: colors.ovulation,
                          title: '外观',
                          subtitle: _labelOf(mode),
                          onTap: () => _pickThemeMode(context, ref, mode),
                        ),
                        const _Divider(),
                        // 在线更新（2026-11-22）：GitHub 直连优先、jsDelivr 镜像兜底
                        _MenuTile(
                          icon: Icons.system_update_outlined,
                          tint: colors.weightUp,
                          title: '检查更新',
                          subtitle: '当前 v$kAppVersion · GitHub / jsDelivr 双通道',
                          onTap: () => context.push('/me/update'),
                        ),
                        const _Divider(),
                        _MenuTile(
                          icon: Icons.info_outline,
                          tint: colors.weightUp,
                          title: '关于',
                          subtitle: '免责声明 · 数据来源 · 隐私政策 · 版本',
                          onTap: () => context.push('/me/data-sources'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXl),
                  Center(
                    child: Text(
                      '月记 · 数据只存在这台手机里',
                      style: AppTokens.caption.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(90),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spaceXxl),
                  // 给底部导航留出空间：不然最后一行会被导航条压住
                  const SizedBox(height: AppTokens.spaceXxl * 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 档案摘要。没填档案时给一句"去哪儿点"，而不是空白。
  static String _profileSubtitle(UserProfile? p, CalorieBudget? b) {
    if (p == null) return '还没填档案，点这里填身高体重';
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

/// 渐变头里的"我是谁"。
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.subtitle, required this.onTap});

  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(46),
            borderRadius: AppTokens.borderL,
          ),
          child: const Icon(
            Icons.nightlight_round,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: AppTokens.spaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '月记',
                style: AppTokens.headline.copyWith(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTokens.caption.copyWith(
                  color: Colors.white.withAlpha(210),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.spaceS),
        Material(
          color: Colors.white.withAlpha(40),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.edit_outlined, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// 菜单行：圆角色块图标 + 标题 + 状态副标题 + 箭头。
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceM,
          vertical: AppTokens.spaceM,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tint.withAlpha(24),
                borderRadius: AppTokens.borderM,
              ),
              child: Icon(icon, size: 20, color: tint),
            ),
            const SizedBox(width: AppTokens.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AppTokens.title),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTokens.caption.copyWith(
                      color: scheme.onSurface.withAlpha(135),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: scheme.onSurface.withAlpha(90),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62),
      child: Divider(
        height: 1,
        color: Theme.of(context).colorScheme.onSurface.withAlpha(10),
      ),
    );
  }
}
