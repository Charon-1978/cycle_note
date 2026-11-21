// lib/core/error/error_handler.dart
//
// 本地错误捕获：给用户人话提示 + 保留现场，**不上报任何数据**。
//
// 约束（AGENTS.md R7 / §9）：
//   · 不接入任何第三方崩溃上报（Sentry / Bugly / Firebase）
//   · 日志中禁止出现体重、经期、性生活等健康字段的原始值
//     —— 因此本实现只记录「异常类型 + 消息 + 栈」，不序列化任何业务对象
//   · 日志写入自身必须 try/catch，避免日志把 App 再搞崩一次
//
// 容量控制：单文件 1 MB 轮转，保留 7 天。

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ErrorHandler {
  ErrorHandler._();

  static const String _logDirName = 'logs';
  static const String _logPrefix = 'error_';
  static const int maxBytesPerFile = 1024 * 1024; // 1 MB
  static const int keepDays = 7;

  static bool _installed = false;

  /// 在 runApp 之前调用。
  static Future<void> install() async {
    if (_installed) return;
    _installed = true;

    FlutterError.onError = (details) {
      // 保留默认的控制台输出，便于开发期排查
      FlutterError.presentError(details);
      unawaited(_write('flutter', details.exception, details.stack));
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(_write('platform', error, stack));
      return true; // 已处理，不再向系统抛出
    };

    ErrorWidget.builder = friendlyErrorWidget;

    unawaited(_purgeExpired());
  }

  /// release 下不显示堆栈，只给一句人话。
  static Widget friendlyErrorWidget(FlutterErrorDetails details) {
    // 注意：ErrorWidget 会在没有 MaterialApp / Theme 的上下文里被调用，
    // 因此这里**不能**依赖 Theme / context.colors，颜色只能写死。
    // 这是 R10（禁止硬编码颜色）的唯一豁免点，已在此处注明。
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFF6F7F9),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '出错了',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C2230),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '你的记录已保存，可以重新打开页面再试一次',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7486)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- 内部 ----------------

  static Future<void> _write(
    String source,
    Object error,
    StackTrace? stack,
  ) async {
    try {
      final dir = await _logDir();
      final now = DateTime.now();
      final file = File('${dir.path}/$_logPrefix${_ymd(now)}.log');

      // 超过上限则轮转：改名带时间戳，再新建
      if (await file.exists() && await file.length() > maxBytesPerFile) {
        await file.rename(
          '${dir.path}/$_logPrefix${_ymd(now)}_${now.millisecondsSinceEpoch}.log',
        );
      }

      // 只记录类型与消息，不序列化任何业务数据
      final line = [
        '${now.toIso8601String()} [$source]',
        '${error.runtimeType}: $error',
        if (stack != null) _trimStack(stack),
        '---',
      ].join('\n');

      await File(file.path).writeAsString(
        '$line\n',
        mode: FileMode.append,
        flush: false,
      );
    } catch (_) {
      // 日志失败绝不能影响主流程，静默丢弃
    }
  }

  /// 栈只留前 20 帧，避免日志爆量。
  static String _trimStack(StackTrace stack) {
    final lines = stack.toString().split('\n');
    if (lines.length <= 20) return stack.toString();
    return '${lines.take(20).join('\n')}\n... (${lines.length - 20} more)';
  }

  static Future<Directory> _logDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/$_logDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 删除超过 keepDays 的日志。
  static Future<void> _purgeExpired() async {
    try {
      final dir = await _logDir();
      final deadline = DateTime.now().subtract(const Duration(days: keepDays));
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        try {
          final stat = await entity.stat();
          if (stat.modified.isBefore(deadline)) {
            await entity.delete();
          }
        } catch (_) {
          // 单个文件失败不影响整体清理
        }
      }
    } catch (_) {
      // 忽略
    }
  }

  static String _ymd(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}$m$day';
  }

  /// 调试期用：列出当前日志文件，便于人工核查是否泄露了健康字段。
  @visibleForTesting
  static Future<List<File>> debugListLogs() async {
    final dir = await _logDir();
    final files = <File>[];
    await for (final e in dir.list()) {
      if (e is File) files.add(e);
    }
    return files;
  }
}
