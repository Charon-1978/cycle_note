// lib/features/reminders/services/reminder_service.dart
//
// 提醒服务（P3-2）：flutter_local_notifications + timezone 的平台接线。
//
// 职责划分：
//   · 什么时候触发 → reminder_scheduler.dart（纯函数，可测）
//   · 偏好存哪里   → ReminderSettingsStore（SharedPreferences，可测）
//   · 怎么让系统弹 → ReminderService（平台通道，只能真机验证）
//
// 本地通知，零后端：提醒设置只进 SharedPreferences，闹钟注册进系统
// AlarmManager/WorkManager，卸载即消失，无任何服务器参与。

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_messages.dart';
import 'reminder_scheduler.dart';

/// 提醒偏好（纯数据，可测）。
class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  static const ReminderSettings disabled =
      ReminderSettings(enabled: false, hour: 20, minute: 0);

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.enabled == enabled &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(enabled, hour, minute);

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// 偏好读写。key 从 v1 锁死（'reminder_*'），改名=丢用户设置。
class ReminderSettingsStore {
  static const _kEnabled = 'reminder_daily_enabled';
  static const _kHour = 'reminder_daily_hour';
  static const _kMinute = 'reminder_daily_minute';

  const ReminderSettingsStore();

  Future<ReminderSettings> load() async {
    final sp = await SharedPreferences.getInstance();
    final enabled = sp.getBool(_kEnabled) ?? false;
    final hour = sp.getInt(_kHour) ?? 20;
    final minute = sp.getInt(_kMinute) ?? 0;
    // 脏数据兜底：范围外直接回到默认，不抛异常
    if (!isValidReminderTime(hour, minute)) return ReminderSettings.disabled;
    return ReminderSettings(enabled: enabled, hour: hour, minute: minute);
  }

  Future<void> save(ReminderSettings s) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kEnabled, s.enabled);
    await sp.setInt(_kHour, s.hour);
    await sp.setInt(_kMinute, s.minute);
  }
}

/// 平台接线。所有方法在测试环境（无平台插件）调用都会抛
/// MissingPluginException —— 调用方要么在真机/模拟器里用，要么 catch。
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const int _dailyId = 1001;
  static const String _channelId = 'daily_reminder';
  static const String _channelName = '每日提醒';
  static const String _channelDesc = '每天固定时间提醒记录经期与体重';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// App 启动时调用一次。初始化时区数据 + 插件 + Android 13 通知权限。
  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    tz.setLocalLocation(_resolveLocalTimeZone());

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS 需要证书与后台模式，当前发版目标只有 Android；
    // 留下 Darwin 默认配置以兼容将来 iOS 化，不阻塞当前平台。
    const darwinInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: darwinInit),
    );

    // Android 13+ 运行时通知权限；13 以下该调用是 no-op
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// 应用（或变更）提醒设置。关 → 取消已注册闹钟；开 → 注册每日重复。
  Future<void> apply(ReminderSettings settings) async {
    if (!_initialized) await init();

    if (!settings.enabled) {
      await _plugin.cancel(_dailyId);
      return;
    }

    final trigger = _nextTrigger(settings);
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      styleInformation: BigTextStyleInformation(''),
    );
    const details = NotificationDetails(android: androidDetails);

    // 文案按"触发那天"轮换；同一天重排也是同一句，不会跳来跳去。
    final msg = reminderMessageFor(trigger);

    await _plugin.zonedSchedule(
      _dailyId,
      msg.title,
      msg.body,
      trigger,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// 把纯函数结果换算成本地时区的 TZDateTime。
  tz.TZDateTime _nextTrigger(ReminderSettings s) {
    final next = nextDailyTrigger(
      now: DateTime.now(),
      hour: s.hour,
      minute: s.minute,
    );
    return tz.TZDateTime.from(next, tz.local);
  }

  /// 本地时区解析。
  ///
  /// DateTime.timeZoneName 在不同机型上可能是 "CST"、"GMT+8"、"中国标准时间"
  /// 之类的不规范值，逐个尝试；全都不认识就回退 Asia/Shanghai——
  /// 当前产品面向国内用户，这个回退比 UTC 正确得多。
  static tz.Location _resolveLocalTimeZone() {
    final name = DateTime.now().timeZoneName;
    const candidates = <String>[
      'Asia/Shanghai',
      'Asia/Chongqing',
      'Asia/Hong_Kong',
      'CST',
      'GMT+8',
      'UTC+8',
    ];
    for (final c in candidates) {
      try {
        if (c == name || (name.contains('+8') && c.startsWith('Asia'))) {
          return tz.getLocation(c);
        }
      } catch (_) {
        // Location 不存在时 getLocation 抛异常，换下一个候选
      }
    }
    return tz.getLocation('Asia/Shanghai');
  }
}
