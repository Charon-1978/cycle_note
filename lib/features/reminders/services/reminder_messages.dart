// lib/features/reminders/services/reminder_messages.dart
//
// 每日提醒的文案池（P3-2 验收："文案随机不重复"）。
//
// 为什么用"按日轮换"而不是 Random()：
//   · 同一天重装/重启不该变（否则用户在设置页看到文案跳来跳去）；
//   · 每天必须换（否则"随机"形同虚设）；
//   · 要能单测 —— 传入日期就得到确定的文案。
// 实现：用「距 1970-01-01 的天数」取模，天然满足以上三条。

/// 提醒正文池。写"能立刻做的一个小动作"，不写空泛的鼓励。
const List<String> kReminderMessages = <String>[
  '花一分钟记一下今天的经期与体重，趋势才看得出来。',
  '今天还没记体重的，睡前称一下就好。',
  '记一句今天的经量，下次预测会更准。',
  '顺手记下今天的饮食，余额才知道还剩多少。',
  '今天走了多少路？记一笔也算运动。',
  '周期数据攒够两次，预测就开始靠谱了。',
  '体重每天波动 1 kg 都正常，看 7 天平均才有意义。',
  '经期前后食欲变高很常见，记下来就好，不用纠结。',
  '今天的经量、痛感各点一下，日历会更完整。',
  '睡前两分钟：体重、饮食、经量，记哪个都行。',
];

/// 提醒标题池（通知栏第一行）。
const List<String> kReminderTitles = <String>[
  '该记录今天的情况啦',
  '今天的记录还没写',
  '两分钟记一笔？',
  '月记 · 今天',
];

/// 第 [day] 天用的提醒文案（同日恒定、隔日变化）。
({String title, String body}) reminderMessageFor(DateTime day) {
  final sinceEpoch = DateTime(day.year, day.month, day.day)
      .difference(DateTime(1970, 1, 1))
      .inDays;
  final body = kReminderMessages[sinceEpoch % kReminderMessages.length];
  final title = kReminderTitles[sinceEpoch % kReminderTitles.length];
  return (title: title, body: body);
}
