// lib/features/reminders/services/reminder_scheduler.dart
//
// 提醒调度的**纯函数**部分（P3-2）。
//
// 手册验收明确要求"调度计算做成纯函数可测"：什么时候触发下一次提醒
// 与插件、时区库、平台通道无关，只取决于 now 和设定的时刻。
// 平台相关部分在 reminder_service.dart 里，这里永远不 import 插件。
//
// 2026-11 补充（对齐计划书 P3-2 的"不打扰"要求）：
//   · 22:00–07:00 是静默时段，**不允许**在这里写日程；
//   · 用户选了静默时段内的时刻 → 顺延到最近一个可提醒的时刻（不是静默丢弃，
//     否则用户会以为"我明明开了提醒却不响"）；
//   · 文案按日期轮换（reminder_messages.dart），不固定一条。

/// 静默时段（含起点，不含终点）：22:00 到次日 07:00。
const int kQuietHourStart = 22;
const int kQuietHourEnd = 7;

/// 这个时刻是否落在静默时段内。
///
/// 注意跨零点：23:30 与 06:30 都算静默，07:00 整不算（它是结束边界）。
bool isQuietTime(int hour) {
  if (hour >= kQuietHourStart) return true; // 22, 23
  return hour < kQuietHourEnd; // 0..6
}

/// 把落在静默时段的时刻推到最近的可提醒时刻。
///
/// 例：设 23:10 → 顺延到次日 07:10；设 05:00 → 当天 07:00。
/// 返回 (hour, minute, dayOffset)。
({int hour, int minute, int dayOffset}) moveOutOfQuietHours({
  required int hour,
  required int minute,
}) {
  RangeError.checkValueInInterval(hour, 0, 23, 'hour');
  RangeError.checkValueInInterval(minute, 0, 59, 'minute');

  if (!isQuietTime(hour)) return (hour: hour, minute: minute, dayOffset: 0);

  // 凌晨段（0–6 点）：当天挪到 07:00；晚间段（22–23 点）：次日同一分钟。
  if (hour < kQuietHourEnd) {
    return (hour: kQuietHourEnd, minute: minute, dayOffset: 0);
  }
  return (hour: kQuietHourEnd, minute: minute, dayOffset: 1);
}

/// 每日提醒的下一个触发时刻。
///
/// 规则：
///   · 先按 [moveOutOfQuietHours] 把时刻挪出静默时段；
///   · 今天 [hour]:[minute] 还没到 → 今天；
///   · 已经到了或过了（含正好等于 now 这一分钟）→ 明天同一时刻。
///     "正好等于"归明天是刻意的：用户在 08:00:30 保存 08:00 的提醒，
///     立刻弹一条等于没意义，语义应为"明天见"。
///
/// [now] 任意秒数都会被截断到分钟精度参与比较。
DateTime nextDailyTrigger({
  required DateTime now,
  required int hour,
  required int minute,
}) {
  RangeError.checkValueInInterval(hour, 0, 23, 'hour');
  RangeError.checkValueInInterval(minute, 0, 59, 'minute');

  final moved = moveOutOfQuietHours(hour: hour, minute: minute);
  final atMinute = DateTime(now.year, now.month, now.day, moved.hour, moved.minute)
      .add(Duration(days: moved.dayOffset));
  final nowMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);

  if (atMinute.isAfter(nowMinute)) return atMinute;
  return atMinute.add(const Duration(days: 1));
}

/// 时间选择合法性（UI 保存前最后一道闸）。
bool isValidReminderTime(int hour, int minute) {
  return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
}

/// 提醒时刻的展示文案。落在静默时段时直接告诉用户会被挪到几点，
/// 避免"设了 23:00 却 7 点才响"的困惑。
String reminderTimeLabel(int hour, int minute) {
  final hh = hour.toString().padLeft(2, '0');
  final mm = minute.toString().padLeft(2, '0');
  if (!isQuietTime(hour)) return '$hh:$mm';

  final moved = moveOutOfQuietHours(hour: hour, minute: minute);
  final mhh = moved.hour.toString().padLeft(2, '0');
  final mmm = moved.minute.toString().padLeft(2, '0');
  return '$hh:$mm（静默时段，实际 $mhh:$mmm）';
}
