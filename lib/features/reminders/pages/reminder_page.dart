// lib/features/reminders/pages/reminder_page.dart
//
// 每日提醒设置页（P3-2）。
//
// 交互：开关 + 时间选择。改动立即生效（保存偏好 + 注册/取消系统闹钟），
// 没有"保存"按钮——这类设置不该让用户多点一步。
//
// 平台边界：注册闹钟走平台通道，测试环境/不支持的平台调用会抛异常；
// 这里 catch 后用 SnackBar 明说"设备不支持"，偏好照常保存——
// 换到支持的设备后打开开关即可，设置不丢。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../services/reminder_service.dart';
import '../services/reminder_scheduler.dart';

/// 提醒偏好。档案之外的小设置，直接 family 透传 FutureProvider。
final reminderSettingsProvider = FutureProvider<ReminderSettings>((ref) {
  return const ReminderSettingsStore().load();
});

class ReminderPage extends ConsumerStatefulWidget {
  const ReminderPage({super.key});

  @override
  ConsumerState<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends ConsumerState<ReminderPage> {
  ReminderSettings? _settings;

  @override
  void initState() {
    super.initState();
    ref.read(reminderSettingsProvider.future).then((s) {
      if (mounted) setState(() => _settings = s);
    });
  }

  Future<void> _update(ReminderSettings s) async {
    setState(() => _settings = s);
    await const ReminderSettingsStore().save(s);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ReminderService.instance.apply(s);
    } catch (_) {
      // 无平台插件（测试环境/桌面端）→ 闹钟没注册上，但要告诉用户
      if (s.enabled) {
        messenger.showSnackBar(
          const SnackBar(content: Text('当前设备无法注册系统提醒，设置已保存')),
        );
      }
    }
  }

  Future<void> _pickTime() async {
    final current = _settings ?? ReminderSettings.disabled;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: '选择每日提醒时间',
    );
    if (picked == null) return;
    if (!isValidReminderTime(picked.hour, picked.minute)) return;
    await _update(current.copyWith(hour: picked.hour, minute: picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final s = _settings;

    return Scaffold(
      appBar: AppBar(title: const Text('每日提醒'), centerTitle: false),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.pagePadding,
                vertical: AppTokens.spaceM,
              ),
              children: [
                SwitchListTile(
                  value: s.enabled,
                  onChanged: (v) =>
                      _update(s.copyWith(enabled: v)),
                  title: const Text('每天提醒我记录'),
                  subtitle: const Text('本地通知，不联网、不上传任何数据'),
                ),
                const Divider(height: 1),
                ListTile(
                  enabled: s.enabled,
                  title: const Text('提醒时间'),
                  subtitle: Text(s.timeLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: s.enabled ? _pickTime : null,
                ),
                const SizedBox(height: AppTokens.spaceM),
                Text(
                  '提醒使用系统定时器（AlarmManager），精确到分钟。'
                  '修改系统时间或重启手机后，系统会自动恢复闹钟。',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                  ),
                ),
              ],
            ),
    );
  }
}
