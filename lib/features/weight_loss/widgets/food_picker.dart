// lib/features/weight_loss/widgets/food_picker.dart
//
// 记饮食弹层（P2-3）。三段式：
//   A 选食物（搜索 + 分类过滤）
//   B 定数量（按份 / 按克 双口径）+ 选餐次 → 返回 FoodEntry
//   C 自建食物（搜不到时的兜底，手册标注"必做"）
//
// 两个关键设计：
//   · 双口径输入不是两个功能，是同一件事的两种习惯：有人只记"一碗饭"，
//     有人用厨房秤记"150 g"。换算锚点是 unitGrams，克数是唯一落库口径。
//   · 自建食物保存后**直接进入 B 段**接着记这一餐，不让用户"保存成功"后再
//     重新搜一遍 —— 那一步是纯摩擦。
//
// 禁止项（手册 P2-3）：不做拍照识别；不改 seed_foods.json 数值。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_tokens.dart';
import '../../../core/widgets/feedback/empty_state.dart';
import '../models/weight_loss_models.dart';
import '../providers/weight_loss_providers.dart';

/// 记录一条饮食需要的全部信息。
class FoodEntry {
  const FoodEntry({
    required this.food,
    required this.grams,
    required this.mealType,
  });

  final FoodItem food;

  /// 落库口径统一是克。
  final double grams;

  /// breakfast / lunch / dinner / snack
  final String mealType;
}

/// 餐次展示名。key 与 MealLogs.mealType 的取值一致。
const Map<String, String> kMealLabels = {
  'breakfast': '早餐',
  'lunch': '午餐',
  'dinner': '晚餐',
  'snack': '加餐',
};

/// 按当前时间猜餐次。猜错了用户会改，猜对了少点一下。
String defaultMealType([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 10) return 'breakfast';
  if (h < 14) return 'lunch';
  if (h < 21) return 'dinner';
  return 'snack';
}

Future<FoodEntry?> showFoodPicker(
  BuildContext context, {
  required List<FoodItem> foods,
  String? initialMealType,
}) {
  return showModalBottomSheet<FoodEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _FoodPickerSheet(
      foods: foods,
      initialMealType: initialMealType,
    ),
  );
}

class _FoodPickerSheet extends ConsumerStatefulWidget {
  const _FoodPickerSheet({required this.foods, this.initialMealType});

  final List<FoodItem> foods;

  /// 从「今日」页点某个餐次进来时预选该餐次；为空则按当前时间猜。
  final String? initialMealType;

  @override
  ConsumerState<_FoodPickerSheet> createState() => _FoodPickerSheetState();
}

class _FoodPickerSheetState extends ConsumerState<_FoodPickerSheet> {
  /// null = 还在 A 段选食物；非空 = 已进入 B 段定数量
  FoodItem? _selected;

  @override
  Widget build(BuildContext context) {
    // 键盘弹起时可用高度要减掉键盘：原来固定 82% 屏高，B 段的"完成"按钮
    // 会被键盘压住（1080x2400 实测，数字键盘约 40% 屏高）。
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final available = MediaQuery.sizeOf(context).height - insets;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: SizedBox(
        height: available * 0.82,
        child: _selected == null
            ? _PickStage(
                foods: widget.foods,
                onPicked: (f) => setState(() => _selected = f),
                onCustomCreated: (f) => setState(() => _selected = f),
              )
            : _QuantityStage(
                food: _selected!,
                initialMealType: widget.initialMealType ?? defaultMealType(),
                onCancel: () => setState(() => _selected = null),
                onDone: (entry) => Navigator.of(context).pop(entry),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// A 段：选食物
// ---------------------------------------------------------------------------

class _PickStage extends StatefulWidget {
  const _PickStage({required this.foods, required this.onPicked, required this.onCustomCreated});

  final List<FoodItem> foods;
  final ValueChanged<FoodItem> onPicked;
  final ValueChanged<FoodItem> onCustomCreated;

  @override
  State<_PickStage> createState() => _PickStageState();
}

class _PickStageState extends State<_PickStage> {
  String _keyword = '';
  String? _category; // null = 全部

  static const Map<String, String> _categoryLabels = {
    'staple': '主食',
    'protein': '蛋白',
    'vegetable': '蔬菜',
    'fruit': '水果',
    'dairy': '乳制品',
    'fat': '油脂',
    'custom': '自建',
  };

  List<FoodItem> get _filtered {
    var list = widget.foods;
    if (_category != null) {
      list = list.where((f) => f.category == _category).toList();
    }
    final k = _keyword.trim().toLowerCase();
    if (k.isNotEmpty) {
      list = list
          .where((f) => f.name.toLowerCase().contains(k))
          .toList(growable: false);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = _filtered;
    final categories = _categoryLabels.keys
        .where((c) => widget.foods.any((f) => f.category == c))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: Row(
            children: [
              Text('记录饮食', style: AppTokens.headline),
              const Spacer(),
              Text(
                '共 ${widget.foods.length} 种',
                style: AppTokens.caption.copyWith(
                  color: scheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spaceM),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _keyword = v),
                  decoration: InputDecoration(
                    hintText: '搜索食物',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: const OutlineInputBorder(
                      borderRadius: AppTokens.borderS,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spaceM),
              OutlinedButton.icon(
                onPressed: () => _openCustomForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('自建'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spaceS),
        SizedBox(
          height: AppTokens.minTouchTarget * 0.7,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pagePadding,
            ),
            children: [
              ChoiceChip(
                label: const Text('全部'),
                selected: _category == null,
                onSelected: (_) => setState(() => _category = null),
              ),
              const SizedBox(width: AppTokens.spaceXs),
              for (final c in categories) ...[
                ChoiceChip(
                  label: Text(_categoryLabels[c] ?? c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
                const SizedBox(width: AppTokens.spaceXs),
              ],
            ],
          ),
        ),
        const Divider(height: AppTokens.spaceL),
        Expanded(
          child: list.isEmpty
              ? EmptyState(
                  compact: true,
                  icon: Icons.search_off,
                  title: '没有找到',
                  message: '换个词试试，或者自己建一条',
                  actionLabel: '自建食物',
                  onAction: () => _openCustomForm(context),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spaceS,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final f = list[i];
                    return ListTile(
                      dense: true,
                      title: Text(f.name, style: AppTokens.body),
                      subtitle: Text(
                        '${f.kcalPer100g.toStringAsFixed(0)} kcal/100g'
                        ' · 1${f.unitName}≈${f.unitGrams.toStringAsFixed(0)}g',
                        style: AppTokens.caption.copyWith(
                          color: scheme.onSurface.withAlpha(120),
                        ),
                      ),
                      trailing: Text(
                        '约 ${f.kcalOf(f.unitGrams).round()} kcal/${f.unitName}',
                        style: AppTokens.caption.copyWith(
                          color: scheme.onSurface.withAlpha(160),
                        ),
                      ),
                      onTap: () => widget.onPicked(f),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _openCustomForm(BuildContext context) async {
    final created = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _CustomFoodForm(),
    );
    if (created != null) widget.onCustomCreated(created);
  }
}

// ---------------------------------------------------------------------------
// B 段：定数量（按份 / 按克）
// ---------------------------------------------------------------------------

class _QuantityStage extends StatefulWidget {
  const _QuantityStage({
    required this.food,
    required this.initialMealType,
    required this.onCancel,
    required this.onDone,
  });

  final FoodItem food;
  final String initialMealType;
  final VoidCallback onCancel;
  final ValueChanged<FoodEntry> onDone;

  @override
  State<_QuantityStage> createState() => _QuantityStageState();
}

class _QuantityStageState extends State<_QuantityStage> {
  /// true = 按份，false = 按克。克数是唯一落库口径。
  bool _byUnit = true;

  late final TextEditingController _ctrl =
      TextEditingController(text: '1');
  late String _mealType = widget.initialMealType;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double? get _grams {
    final v = double.tryParse(_ctrl.text.trim());
    if (v == null || v <= 0 || v.isNaN || v.isInfinite) return null;
    final g = _byUnit ? v * widget.food.unitGrams : v;
    // 上限 3000 g：超过 3 kg 的单笔记录基本是单位搞反了（比如把 150 g 写成 1500 份）
    if (g > 3000) return null;
    return g;
  }

  String? get _error {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null) return '请输入数字';
    final g = _byUnit ? v * widget.food.unitGrams : v;
    if (g <= 0) return '要大于 0';
    if (g > 3000) return '单笔不超过 3000 g';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final f = widget.food;
    final grams = _grams;
    final kcal = grams == null ? null : f.kcalOf(grams);

    return Column(
      children: [
        // 头部：食物名 + 返回
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: Row(
            children: [
              InkWell(
                borderRadius: AppTokens.borderS,
                onTap: widget.onCancel,
                child: Padding(
                  padding: const EdgeInsets.all(AppTokens.spaceXs),
                  child: Icon(Icons.arrow_back, size: 20,
                      color: scheme.onSurface.withAlpha(160)),
                ),
              ),
              const SizedBox(width: AppTokens.spaceS),
              Expanded(
                child: Text(
                  f.name,
                  style: AppTokens.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${f.kcalPer100g.toStringAsFixed(0)} kcal/100g',
                style: AppTokens.caption.copyWith(
                  color: scheme.onSurface.withAlpha(140),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spaceL),

        // 餐次
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: Row(
            children: [
              Text('这餐是', style: AppTokens.label),
              const SizedBox(width: AppTokens.spaceM),
              Expanded(
                child: Wrap(
                  spacing: AppTokens.spaceXs,
                  children: [
                    for (final e in kMealLabels.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: _mealType == e.key,
                        onSelected: (_) => setState(() => _mealType = e.key),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spaceL),

        // 数量：口径切换 + 输入
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pagePadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('按份'),
                    icon: Icon(Icons.restaurant, size: 16),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('按克'),
                    icon: Icon(Icons.scale, size: 16),
                  ),
                ],
                selected: {_byUnit},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _byUnit = v.first),
              ),
              const SizedBox(width: AppTokens.spaceM),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: _byUnit ? '份数' : '克数',
                    suffixText: _byUnit ? '${f.unitName}（≈${f.unitGrams.toStringAsFixed(0)}g）' : 'g',
                    errorText: _error,
                    border: const OutlineInputBorder(
                      borderRadius: AppTokens.borderS,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // 底部：实时换算 + 保存
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.pagePadding),
            child: SizedBox(
              width: double.infinity,
              height: AppTokens.minTouchTarget,
              child: FilledButton(
                onPressed: grams == null
                    ? null
                    : () {
                        // 闭包里拿不到空提升，先拷一份非空值
                        final g = grams;
                        widget.onDone(FoodEntry(
                          food: f,
                          grams: g,
                          mealType: _mealType,
                        ));
                      },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                ),
                child: Text(
                  kcal == null || grams == null
                      ? '填写数量'
                      : '记 ${(grams / f.unitGrams).toStringAsFixed(1)}${f.unitName}'
                          '（${grams.round()} g · ${kcal.round()} kcal）',
                  // 主按钮是品牌色实底，文字必须用白色；
                  // 原来写的是 calorieOk（绿），在红底上读不清。
                  style: AppTokens.title.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// C 段：自建食物
// ---------------------------------------------------------------------------

class _CustomFoodForm extends ConsumerStatefulWidget {
  const _CustomFoodForm();

  @override
  ConsumerState<_CustomFoodForm> createState() => _CustomFoodFormState();
}

class _CustomFoodFormState extends ConsumerState<_CustomFoodForm> {
  final _nameCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _unitGramsCtrl = TextEditingController(text: '100');
  final _unitNameCtrl = TextEditingController(text: '份');

  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _kcalCtrl,
      _proteinCtrl,
      _fatCtrl,
      _carbCtrl,
      _unitGramsCtrl,
      _unitNameCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController c) {
    final raw = c.text.trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null || v.isNaN || v.isInfinite || v < 0) return null;
    return v;
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty && (_num(_kcalCtrl) ?? -1) >= 0;

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final kcal = _num(_kcalCtrl);
    if (name.isEmpty || kcal == null) return;

    setState(() => _saving = true);
    try {
      final food = await ref.read(weightLossRepositoryProvider).saveCustomFood(
            name: name,
            kcalPer100g: kcal,
            proteinPer100g: _num(_proteinCtrl) ?? 0,
            fatPer100g: _num(_fatCtrl) ?? 0,
            carbPer100g: _num(_carbCtrl) ?? 0,
            unitGrams: _num(_unitGramsCtrl) ?? 100,
            unitName: _unitNameCtrl.text.trim().isEmpty
                ? '份'
                : _unitNameCtrl.text.trim(),
          );
      // 食物库要刷新，否则下次打开搜不到刚建的
      invalidateWeightLossChain(ref.invalidate);
      if (!mounted) return;
      Navigator.of(context).pop(food); // 把结果带回 A 段，直接进入 B 段
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.pagePadding,
          0,
          AppTokens.pagePadding,
          AppTokens.spaceL,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('自建食物', style: AppTokens.headline),
                const Spacer(),
                Text(
                  '只填名字和热量也能用',
                  style: AppTokens.caption.copyWith(
                    color: scheme.onSurface.withAlpha(140),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceL),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              maxLength: 30,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: '名字',
                border: OutlineInputBorder(borderRadius: AppTokens.borderS),
                counterText: '',
              ),
            ),
            const SizedBox(height: AppTokens.spaceM),
            TextField(
              controller: _kcalCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: '热量（每 100 g）',
                suffixText: 'kcal',
                border: OutlineInputBorder(borderRadius: AppTokens.borderS),
              ),
            ),
            const SizedBox(height: AppTokens.spaceM),
            Row(
              children: [
                for (final (i, entry) in [
                  ('蛋白质 g', _proteinCtrl),
                  ('脂肪 g', _fatCtrl),
                  ('碳水 g', _carbCtrl),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: AppTokens.spaceS),
                  Expanded(
                    child: TextField(
                      controller: entry.$2,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                      ],
                      decoration: InputDecoration(
                        labelText: entry.$1,
                        border: const OutlineInputBorder(
                          borderRadius: AppTokens.borderS,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppTokens.spaceM),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _unitGramsCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: '一份的克数',
                      suffixText: 'g',
                      border: OutlineInputBorder(
                        borderRadius: AppTokens.borderS,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spaceS),
                Expanded(
                  child: TextField(
                    controller: _unitNameCtrl,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      labelText: '一份叫什么',
                      border: OutlineInputBorder(
                        borderRadius: AppTokens.borderS,
                      ),
                      isDense: true,
                      counterText: '',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spaceL),
            SizedBox(
              height: AppTokens.minTouchTarget,
              child: FilledButton(
                onPressed: (_valid && !_saving) ? _save : null,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                ),
                child: Text(
                  _saving ? '保存中…' : '保存并选用',
                  style: AppTokens.title,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
