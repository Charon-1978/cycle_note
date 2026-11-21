// lib/features/reminders/services/reminder_scheduler.dart
//
// 提醒调度的**纯函数**部分（P3-2）。
//
// 手册验收明确要求"调度计算做成纯函数可测"：什么时候触发下一次提醒
// 与插件、时区库、平台通道无关，只取决于 now 和设定的时刻。
// 平台相关部分在 reminder_service.dart 里，这里永远不 import 插件。

/// 每日提醒的下一个触发时刻。
///
/// 规则：
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

  final atMinute =
      DateTime(now.year, now.month, now.day, hour, minute);
  final nowMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
  if (atMinute.isAfter(nowMinute)) return atMinute;
  return atMinute.add(const Duration(days: 1));
}

/// 时间选择合法性（UI 保存前最后一道闸）。
bool isValidReminderTime(int hour, int minute) {
  return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
}
