// lib/features/weight_loss/widgets/weight_input.dart
//
// 快速记录体重（QuickActionSheet 的「体重」态，P1-4 步骤 1）。
//
// 交互要点：
//   · 打开时预填最近一次体重 —— 用户通常每天只变化零点几公斤，
//     从零开始输入反而更容易错。
//   · 体脂率可选。填了会在趋势里多一个参考，但**不影响** BMR
//     （那是身体档案页的事，两个入口的职责不能混）。
//   · 保存成功后弹层自动关闭，今日页/趋势页通过 invalidate 自动刷新，
//     不需要手动"下拉刷新"。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../data/local/database/database_provider.dart';
import '../providers/weight_loss_providers.dart';
import '../services/today_widget_service.dart';

/// 合法体重区间，与身体档案页保持一致。
const double kMinWeightKg = 25;
const double kMaxWeightKg = 300;

/// 合法体脂率区间。超出视为手误，直接拒绝而不是悄悄接受。
const double kMinBodyFat = 3;
const double kMaxBodyFat = 65;

class WeightQuickInput extends ConsumerStatefulWidget {
  const WeightQuickInput({super.key, this.onSaved});

  final VoidCallback? onSaved;

  @override
  ConsumerState<WeightQuickInput> createState() => _WeightQuickInputState();
}

class _WeightQuickInputState extends ConsumerState<WeightQuickInput> {
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _fatCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final latest = await ref.read(latestWeightProvider.future);
    if (!mounted || latest == null) return;
    setState(() {
      // 62.0 → "62.0"，保留一位小数提示格式
      _weightCtrl.text = latest.toStringAsFixed(1);
    });
  }

  double? get _weight {
    final v = double.tryParse(_weightCtrl.text.trim());
    if (v == null || v.isNaN || v.isInfinite) return null;
    if (v < kMinWeightKg || v > kMaxWeightKg) return null;
    return v;
  }

  double? get _bodyFat {
    final raw = _fatCtrl.text.trim();
    if (raw.isEmpty) return null; // 可选
    final v = double.tryParse(raw);
    if (v == null) return null;
    if (v < kMinBodyFat || v > kMaxBodyFat) return null;
    return v;
  }

  String? get _weightError {
    final raw = _weightCtrl.text.trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null) return '请输入数字';
    if (v < kMinWeightKg || v > kMaxWeightKg) {
      return '体重应在 ${kMinWeightKg.toInt()}–${kMaxWeightKg.toInt()} kg 之间';
    }
    return null;
  }

  String? get _fatError {
    final raw = _fatCtrl.text.trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null) return '请输入数字';
    if (v < kMinBodyFat || v > kMaxBodyFat) {
      return '体脂率应在 ${kMinBodyFat.toInt()}–${kMaxBodyFat.toInt()}% 之间';
    }
    return null;
  }

  bool get _canSave => _weight != null && _weightError == null && !_saving;

  Future<void> _save() async {
    final w = _weight;
    if (w == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写体重')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(weightLossRepositoryProvider).addWeight(
            weightKg: w,
            bodyFatPercent: _bodyFat,
          );
      invalidateWeightLossChain(ref.invalidate);

      // P3-3：记录后同步桌面小组件。非关键路径，平台不支持时静默。
      try {
        await const TodayWidgetService()
            .refresh(ref.read(appDatabaseProvider));
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭弹层
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('已记录 ${w.toStringAsFixed(1)} kg')));
      widget.onSaved?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _weightCtrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: '体重',
            suffixText: 'kg',
            errorText: _weightError,
            border: const OutlineInputBorder(borderRadius: AppTokens.borderS),
          ),
        ),
        const SizedBox(height: AppTokens.spaceM),
        TextField(
          controller: _fatCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            LengthLimitingTextInputFormatter(5),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: '体脂率（可选）',
            suffixText: '%',
            errorText: _fatError,
            helperText: '填了会在趋势里多一条参考线',
            border: const OutlineInputBorder(borderRadius: AppTokens.borderS),
          ),
        ),
        const SizedBox(height: AppTokens.spaceL),
        SizedBox(
          height: AppTokens.minTouchTarget,
          child: FilledButton(
            onPressed: _canSave ? _save : null,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
              ),
            ),
            child: _saving
                ? SizedBox(
                    width: AppTokens.spaceL,
                    height: AppTokens.spaceL,
                    child:
                        const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _weight == null ? '填写体重' : '记 ${_weight!.toStringAsFixed(1)} kg',
                    style: AppTokens.title.copyWith(color: scheme.onPrimary),
                  ),
          ),
        ),
      ],
    );
  }
}
