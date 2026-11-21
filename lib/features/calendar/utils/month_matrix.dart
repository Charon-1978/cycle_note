// lib/features/calendar/utils/month_matrix.dart
//
// 月历矩阵（纯函数，无 Flutter 依赖，可单测）。
//
// 约定：
//   · 每周从**周一**开始（中文习惯），列序为 一 二 三 四 五 六 日
//   · 固定输出 6 行 × 7 列 = 42 格，非本月日期为 null
//     固定行数的好处：切月时网格高度不变，不会跳动

/// 构建某年某月的日历矩阵。
///
/// [month] 为 1–12。
List<List<DateTime?>> buildMonthMatrix(int year, int month) {
  assert(month >= 1 && month <= 12, 'month 必须在 1..12');

  final first = DateTime(year, month, 1);
  // DateTime(year, month + 1, 0) 会归一化到下个月第 0 天 = 本月最后一天
  final daysInMonth = DateTime(year, month + 1, 0).day;

  // Monday = 1 … Sunday = 7 → 偏移 0..6
  final leadingBlanks = (first.weekday - DateTime.monday) % 7;

  final cells = <DateTime?>[];
  for (var i = 0; i < leadingBlanks; i++) {
    cells.add(null);
  }
  for (var d = 1; d <= daysInMonth; d++) {
    cells.add(DateTime(year, month, d));
  }
  // 补满 42 格
  while (cells.length < 42) {
    cells.add(null);
  }

  return [
    for (var i = 0; i < 42; i += 7) cells.sublist(i, i + 7),
  ];
}

/// 上一个月（用于切换）。
DateTime previousMonth(DateTime month) =>
    DateTime(month.year, month.month - 1, 1);

/// 下一个月（用于切换）。
DateTime nextMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 1);

/// 该月第一天。
DateTime firstDayOfMonth(DateTime anyDayInMonth) =>
    DateTime(anyDayInMonth.year, anyDayInMonth.month, 1);

/// 该月最后一天。
DateTime lastDayOfMonth(DateTime anyDayInMonth) =>
    DateTime(anyDayInMonth.year, anyDayInMonth.month + 1, 0);

/// 是否同一天（只比年月日）。
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// 本地零点。
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
