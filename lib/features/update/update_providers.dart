// lib/features/update/update_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_service.dart';

/// 全局单例。测试里用 `updateServiceProvider.overrideWithValue(...)` 注入假实现。
final updateServiceProvider = Provider<UpdateService>((ref) {
  final service = UpdateService();
  ref.onDispose(service.dispose);
  return service;
});
