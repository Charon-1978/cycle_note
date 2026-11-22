// lib/app/router.dart
//
// 导航结构（可行性计划书 ADR-2：4 Tab）。
//
//   /today     今日（唯一 daily hub）
//   /calendar  日历（只管「看」）
//   /trends    趋势（周期 / 体重 / 热量）
//   /me        我的
//
// 旧路径兼容：逆向得到的原路由（/、/record、/calendar/full、/statistics、/profile）
// 一律重定向到新位置，保留 3 个月。避免用户升级后找不到页面。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/pages/calendar_page.dart';
import '../features/me/pages/data_sources_page.dart';
import '../features/me/pages/export_page.dart';
import '../features/me/pages/me_page.dart';
import '../features/me/pages/privacy_page.dart';
import '../features/update/update_page.dart';
import '../features/period/pages/period_history_page.dart';
import '../features/reminders/pages/reminder_page.dart';
import '../features/today/pages/today_page.dart';
import '../features/trends/pages/trends_page.dart';
import '../features/weight_loss/pages/body_profile_page.dart';
import '../features/weight_loss/pages/exercise_log_page.dart';
import '../features/weight_loss/pages/food_log_page.dart';
import '../features/weight_loss/pages/meal_plan_page.dart';
import '../features/weight_loss/pages/weight_log_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      // ---------- 旧路径兼容 ----------
      GoRoute(path: '/', redirect: (_, __) => '/today'),
      GoRoute(path: '/record', redirect: (_, __) => '/today'),
      GoRoute(path: '/calendar/full', redirect: (_, __) => '/calendar'),
      GoRoute(path: '/statistics', redirect: (_, __) => '/trends'),
      GoRoute(path: '/profile', redirect: (_, __) => '/me'),

      // ---------- 二级页（全屏 push，不占 Tab） ----------
      //
      // 放在 shell 之外，这样进入时是标准的全屏推入动画 + 返回手势，
      // 而不是在 Tab 内部替换页面（那样底部导航还留着，用户会以为没进去）。
      GoRoute(
        path: '/me/body-profile',
        builder: (_, __) => const BodyProfilePage(),
      ),
      GoRoute(
        path: '/me/exercise',
        builder: (_, __) => const ExerciseLogPage(),
      ),
      GoRoute(
        path: '/me/weight',
        builder: (_, __) => const WeightLogPage(),
      ),
      GoRoute(
        path: '/me/food',
        builder: (_, __) => const FoodLogPage(),
      ),
      GoRoute(
        path: '/me/meal-plan',
        builder: (_, __) => const MealPlanPage(),
      ),
      GoRoute(
        path: '/me/update',
        builder: (_, __) => const UpdatePage(),
      ),
      GoRoute(
        path: '/me/data-sources',
        builder: (_, __) => const DataSourcesPage(),
      ),
      GoRoute(
        path: '/me/privacy',
        builder: (_, __) => const PrivacyPage(),
      ),
      GoRoute(
        path: '/me/export',
        builder: (_, __) => const ExportPage(),
      ),
      GoRoute(
        path: '/me/reminder',
        builder: (_, __) => const ReminderPage(),
      ),
      GoRoute(
        path: '/period/history',
        builder: (_, __) => const PeriodHistoryPage(),
      ),

      // ---------- 四 Tab ----------
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (_, __) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (_, __) => const CalendarPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trends',
                builder: (_, __) => const TrendsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (_, __) => const MePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _ScaffoldWithNav extends StatelessWidget {
  const _ScaffoldWithNav({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: '今日',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '日历',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: '趋势',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
