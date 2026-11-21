// lib/features/weight_loss/widgets/exercise_picker.dart
//
// 运动选择 + 时长输入（P1-5 的弹层）。
//
// 交互取舍：
//   · 列表里每项直接写「约 N kcal/60 分钟」，按**当前体重**算。
//     用户选运动的真实问题是"这个能消耗多少"，不是"MET 是多少"。
//   · 时长用 chips（15/30/45/60/90）+ 输入框，chips 只负责写值，
//     输入框是唯一数据源 —— 单向，不会出现两边打架。
//   · 底部按钮直接把"结果"写出来：「记 30 分钟 · 约 150 kcal」，
//     让用户在按下去之前就知道会发生什么。
//
// 依赖约束（手册 P1-5 禁止项）：
//   ❌ 不改 ExerciseService.burn 的公式
//   ❌ 不用"当前体重"覆盖历史记录的 weightKgAtTime（那是保存时才拼的）

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_tokens.dart';
import '../services/exercise_service.dart';

/// 弹层的返回值：选了哪项运动、多少分钟。
class ExercisePick {
  const ExercisePick({required this.def, required this.minutes});

  final ExerciseDef def;
  final int minutes;
}

/// 时长合法区间。上限 600 分钟：超过 10 小时基本是手误。
const int kMinExerciseMinutes = 1;
const int kMaxExerciseMinutes = 600;

Future<ExercisePick?> showExercisePicker(
  BuildContext context, {
  required List<ExerciseDef> defs,
  required double weightKg,
}) {
  return showModalBottomSheet<ExercisePick>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ExercisePickerSheet(defs: defs, weightKg: weightKg),
  );
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({required this.defs, required this.weightKg});

  final List<ExerciseDef> defs;
  final double weightKg;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _minutesCtrl = TextEditingController(text: '30');

  ExerciseDef? _selected;
  String _keyword = '';

  static const List<int> _presets = [15, 30, 45, 60, 90];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  int? get _minutes {
    final v = int.tryParse(_minutesCtrl.text.trim());
    if (v == null) return null;
    if (v < kMinExerciseMinutes || v > kMaxExerciseMinutes) return null;
    return v;
  }

  String? get _minutesError {
    final raw = _minutesCtrl.text.trim();
    if (raw.isEmpty) return null;
    final v = int.tryParse(raw);
    if (v == null) return '请输入数字';
    if (v < kMinExerciseMinutes || v > kMaxExerciseMinutes) {
      return '时长需在 $kMinExerciseMinutes–$kMaxExerciseMinutes 分钟之间';
    }
    return null;
  }

  List<ExerciseDef> get _filtered {
    if (_keyword.trim().isEmpty) return widget.defs;
    final k = _keyword.trim().toLowerCase();
    return widget.defs
        .where((e) =>
            e.name.toLowerCase().contains(k) ||
            e.code.toLowerCase().contains(k))
        .toList(growable: false);
  }

  double get _estimatedKcal {
    final m = _minutes;
    final def = _selected;
    if (m == null || def == null) return 0;
    return ExerciseService.burn(
      met: def.met,
      weightKg: widget.weightKg,
      minutes: m,
    );
  }

  bool get _canSubmit => _selected != null && _minutes != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = _filtered;

    return Padding(
      // 键盘弹起时把内容顶上去，否则时长输入框会被挡住
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.pagePadding,
              ),
              child: Row(
                children: [
                  Text('记录运动', style: AppTokens.headline),
                  const Spacer(),
                  Text(
                    '按 ${widget.weightKg.toStringAsFixed(1)} kg 估算',
                    style: AppTokens.caption.copyWith(
                      color: scheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spaceM),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.pagePadding,
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _keyword = v),
                decoration: InputDecoration(
                  hintText: '搜索运动名称',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: const OutlineInputBorder(
                    borderRadius: AppTokens.borderS,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spaceM),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.pagePadding,
              ),
              child: Row(
                children: [
                  Text('时长', style: AppTokens.label),
                  const SizedBox(width: AppTokens.spaceM),
                  for (final p in _presets) ...[
                    ChoiceChip(
                      label: Text('$p'),
                      selected: _minutesCtrl.text.trim() == '$p',
                      onSelected: (_) => setState(() {
                        _minutesCtrl.text = '$p';
                      }),
                    ),
                    const SizedBox(width: AppTokens.spaceXs),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _minutesCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      onChanged: (_) => setState(() {}),
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                        suffixText: '分钟',
                        errorText: _minutesError,
                        isDense: true,
                        border: const OutlineInputBorder(
                          borderRadius: AppTokens.borderS,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: AppTokens.spaceXl),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        '没有匹配的运动',
                        style: AppTokens.body.copyWith(
                          color: scheme.onSurface.withAlpha(140),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spaceS,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final def = list[i];
                        final selected = def.code == _selected?.code;
                        final perHour = ExerciseService.kcalPerHour(
                          met: def.met,
                          weightKg: widget.weightKg,
                        );
                        return ListTile(
                          dense: true,
                          selected: selected,
                          selectedTileColor: scheme.primary.withAlpha(20),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppTokens.borderS,
                          ),
                          leading: Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                          title: Text(def.name, style: AppTokens.body),
                          subtitle: Text(
                            'MET ${def.met.toStringAsFixed(1)}',
                            style: AppTokens.caption.copyWith(
                              color: scheme.onSurface.withAlpha(120),
                            ),
                          ),
                          trailing: Text(
                            '约 $perHour kcal/时',
                            style: AppTokens.caption.copyWith(
                              color: scheme.onSurface.withAlpha(160),
                            ),
                          ),
                          onTap: () => setState(() => _selected = def),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.pagePadding),
                child: SizedBox(
                  width: double.infinity,
                  height: AppTokens.minTouchTarget,
                  child: FilledButton(
                    onPressed: _canSubmit
                        ? () => Navigator.of(context).pop(
                              ExercisePick(
                                def: _selected!,
                                minutes: _minutes!,
                              ),
                            )
                        : null,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusPill),
                      ),
                    ),
                    child: Text(
                      _canSubmit
                          ? '记 ${_minutes!} 分钟 · 约 ${_estimatedKcal.round()} kcal'
                          : '先选一项运动',
                      style: AppTokens.title,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
