// test/reminders/reminder_test.dart
//
// P3-2「提醒系统」验收（可测部分）：
//   · 调度计算是**纯函数**：nextDailyTrigger 的今天/明天/边界行为
//   · 时间合法性校验
//   · 偏好存取：默认值 / 保存后读回 / 脏数据兜底
//
// 平台接线（ReminderService.apply → 系统闹钟）无法在测试环境验证，
// 属于真机验收项；这里只保证纯逻辑与持久化正确。

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cycle_note/features/reminders/services/reminder_scheduler.dart';
import 'package:cycle_note/features/reminders/services/reminder_service.dart';

DateTime at(int y, int m, int d, int h, [int min = 0]) =>
    DateTime(y, m, d, h, min);

void main() {
  group('nextDailyTrigger（纯函数）', () {
    test('今天的时刻还没到 → 今天', () {
      final next = nextDailyTrigger(
        now: at(2026, 3, 10, 7, 0),
        hour: 20,
        minute: 30,
      );
      expect(next, at(2026, 3, 10, 20, 30));
    });

    test('已经过了 → 明天同一时刻', () {
      final next = nextDailyTrigger(
        now: at(2026, 3, 10, 21, 0),
        hour: 20,
        minute: 30,
      );
      expect(next, at(2026, 3, 11, 20, 30));
    });

    test('正好等于 now（分钟精度）→ 明天', () {
      // 用户在 08:00:30 保存 08:00 的提醒 → 明天见（此刻不再弹）
      final now = DateTime(2026, 3, 10, 8, 0, 30);
      final next = nextDailyTrigger(now: now, hour: 8, minute: 0);
      expect(next, at(2026, 3, 11, 8, 0));
    });

    test('跨月边界：1 月 31 日 23:01 设 23:00 → 2 月 1 日', () {
      final next = nextDailyTrigger(
        now: at(2026, 1, 31, 23, 1),
        hour: 23,
        minute: 0,
      );
      expect(next, at(2026, 2, 1, 23, 0));
    });

    test('now 带秒数：08:00:59 < 09:00 → 今天 09:00', () {
      final now = DateTime(2026, 3, 10, 8, 0, 59);
      final next = nextDailyTrigger(now: now, hour: 9, minute: 0);
      expect(next, at(2026, 3, 10, 9, 0));
    });

    test('非法 hour/minute 抛 RangeError', () {
      expect(
        () => nextDailyTrigger(now: at(2026, 3, 10, 8), hour: 24, minute: 0),
        throwsRangeError,
      );
      expect(
        () => nextDailyTrigger(now: at(2026, 3, 10, 8), hour: 8, minute: 60),
        throwsRangeError,
      );
    });
  });

  group('isValidReminderTime', () {
    test('合法与非法边界', () {
      expect(isValidReminderTime(0, 0), isTrue);
      expect(isValidReminderTime(23, 59), isTrue);
      expect(isValidReminderTime(24, 0), isFalse);
      expect(isValidReminderTime(-1, 0), isFalse);
      expect(isValidReminderTime(8, 60), isFalse);
      expect(isValidReminderTime(8, -1), isFalse);
    });
  });

  group('ReminderSettingsStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('默认：关闭、20:00', () async {
      final s = await const ReminderSettingsStore().load();
      expect(s.enabled, isFalse);
      expect(s.hour, 20);
      expect(s.minute, 0);
    });

    test('保存后读回一致', () async {
      const store = ReminderSettingsStore();
      await store.save(const ReminderSettings(enabled: true, hour: 8, minute: 30));
      final s = await store.load();
      expect(s, const ReminderSettings(enabled: true, hour: 8, minute: 30));
    });

    test('脏数据兜底：hour 越界回默认，不抛异常', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'reminder_daily_enabled': true,
        'reminder_daily_hour': 99,
        'reminder_daily_minute': 0,
      });
      final s = await const ReminderSettingsStore().load();
      expect(s, ReminderSettings.disabled);
    });

    test('copyWith 只改指定字段', () {
      const base = ReminderSettings(enabled: false, hour: 9, minute: 15);
      expect(base.copyWith(enabled: true),
          const ReminderSettings(enabled: true, hour: 9, minute: 15));
      expect(base.copyWith(minute: 45),
          const ReminderSettings(enabled: false, hour: 9, minute: 45));
      expect(base.timeLabel, '09:15');
    });
  });
}
