// lib/features/weight_loss/pages/body_profile_page.dart
//
// 身体档案（P1-2）。减脂模块的**唯一入口**，也是热量预算的唯一数据来源。
//
// 交互设计要点：
//   1) 边填边算。用户在改身高体重的当下就要看到「建议摄入」怎么变，
//      不能等点了保存才知道。所以预览用的是本地 state 里临时构造的
//      UserProfile，不落库、不查库。
//   2) 每一步都解释「为什么问这个」。活动水平的每个档位都带一句人话提示，
//      否则用户永远会选「久坐」然后困惑为什么预算这么低。
//   3) 安全边界要显式说出来。触发下限抬升时，明确告知「按你的目标算出的
//      热量过低，已抬到安全线」，而不是悄悄改数字。
//   4) 不填目标体重也能用 —— 按 BMI 22 推荐一个，并且显示出来让用户能看到。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../data/profile_mapper.dart';
import '../models/weight_loss_models.dart';
import '../providers/weight_loss_providers.dart';
import '../services/tdee_service.dart';

/// 新建档案时的默认值。刻意取中间值，让用户只需要微调。
const double _kDefaultAge = 25;
const double _kDefaultHeight = 165;
const double _kDefaultWeight = 55;

/// 小数输入（最多 3 位整数 + 1 位小数，如 165 / 62.5）。
///
/// 用 withFunction 校验**整个结果串**，而不是 FilteringTextInputFormatter
/// 的"按字符放行"——后者配 `^\d{0,3}(\.\d{0,1})?` 会因正则能匹配空串而
/// 全部放行，等于没拦。
final TextInputFormatter _decimalFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) {
    if (newValue.text.isEmpty) return newValue;
    return RegExp(r'^\d{0,3}(\.\d?)?$').hasMatch(newValue.text)
        ? newValue
        : oldValue;
  },
);

/// 整数输入（最多 3 位，如 28）。
final TextInputFormatter _intFormatter = TextInputFormatter.withFunction(
  (oldValue, newValue) {
    if (newValue.text.isEmpty) return newValue;
    return RegExp(r'^\d{0,3}$').hasMatch(newValue.text) ? newValue : oldValue;
  },
);

class BodyProfilePage extends ConsumerStatefulWidget {
  const BodyProfilePage({super.key});

  @override
  ConsumerState<BodyProfilePage> createState() => _BodyProfilePageState();
}

class _BodyProfilePageState extends ConsumerState<BodyProfilePage> {
  static const TdeeService _tdee = TdeeService();

  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _targetCtrl = TextEditingController();

  Sex _sex = Sex.female;
  ActivityLevel _activity = ActivityLevel.light;
  WeightGoal _goal = WeightGoal.lose;
  LossPace _pace = LossPace.standard;

  bool _loaded = false;
  bool _saving = false;

  /// 编辑已有档案时为 true（决定保存时是否保留起始体重）
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // read 在 initState 里是允许的（watch 不行）
    Future.microtask(_loadExisting);
  }

  @override
  void dispose() {
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(weightLossRepositoryProvider);
    final row = await repo.profile();
    final latest = await repo.latestWeight();
    if (!mounted) return;

    final p = row?.toDomain(currentWeightKg: latest);
    setState(() {
      if (p != null) {
        _isEditing = true;
        _sex = p.sex;
        _activity = p.activity;
        _goal = p.goal;
        _pace = p.pace;
        _ageCtrl.text = p.age.toString();
        _heightCtrl.text = _trimNumber(p.heightCm);
        _weightCtrl.text = _trimNumber(p.weightKg);
        _targetCtrl.text =
            p.targetWeightKg == null ? '' : _trimNumber(p.targetWeightKg!);
      } else {
        _ageCtrl.text = _trimNumber(_kDefaultAge);
        _heightCtrl.text = _trimNumber(_kDefaultHeight);
        _weightCtrl.text = _trimNumber(_kDefaultWeight);
      }
      _loaded = true;
    });
  }

  // ---------------- 解析与校验 ----------------

  double? _parse(TextEditingController c) {
    final raw = c.text.trim();
    if (raw.isEmpty) return null;
    final v = double.tryParse(raw);
    if (v == null || v.isNaN || v.isInfinite) return null;
    return v;
  }

  double? get _age => _parse(_ageCtrl);
  double? get _height => _parse(_heightCtrl);
  double? get _weight => _parse(_weightCtrl);

  /// 各字段的合法区间。故意放宽到"极端但真实存在"的范围，
  /// 只拦明显手误（把 165 打成 16.5 / 1650）。
  static const _ageRange = (min: 10.0, max: 100.0);
  static const _heightRange = (min: 100.0, max: 250.0);
  static const _weightRange = (min: 25.0, max: 300.0);

  String? get _ageError => _rangeError(_age, _ageRange.min, _ageRange.max);
  String? get _heightError =>
      _rangeError(_height, _heightRange.min, _heightRange.max);
  String? get _weightError =>
      _rangeError(_weight, _weightRange.min, _weightRange.max);

  static String? _rangeError(double? v, double min, double max) {
    if (v == null) return null; // 空值由"能否计算"统一处理，这里不报红
    if (v < min || v > max) return '应在 ${min.toInt()}–${max.toInt()} 之间';
    return null;
  }

  /// 当前输入能否算出一份完整预算
  UserProfile? get _draftProfile {
    final age = _age;
    final height = _height;
    final weight = _weight;
    if (age == null || height == null || weight == null) return null;
    if (_ageError != null || _heightError != null || _weightError != null) {
      return null;
    }

    final target = _parse(_targetCtrl);
    // 目标体重也做区间校验，非法就当没填（不让一个手误的 0 参与计算）
    final validTarget = (target != null &&
            target >= _weightRange.min &&
            target <= _weightRange.max)
        ? target
        : null;

    return UserProfile(
      sex: _sex,
      age: age.round(),
      heightCm: height,
      weightKg: weight,
      activity: _activity,
      goal: _goal,
      pace: _pace,
      targetWeightKg: validTarget,
    );
  }

  CalorieBudget? get _draftBudget {
    final p = _draftProfile;
    if (p == null) return null;
    return _tdee.calculate(p);
  }

  // ---------------- 保存 ----------------

  Future<void> _save() async {
    final p = _draftProfile;
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先把年龄、身高、体重填完整')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(weightLossRepositoryProvider);

      await repo.saveProfile(p, preserveStartWeight: _isEditing);

      // 体重变了就同步写一条体重记录，否则趋势页/7 日平均看不到这次变化。
      // 手动填档案也是"称了一次"，不该丢。
      final latest = await repo.latestWeight();
      if (latest == null || (latest - p.weightKg).abs() > 0.05) {
        await repo.addWeight(weightKg: p.weightKg, note: '档案更新');
      }

      invalidateWeightLossChain(ref.invalidate);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('身体档案'),
        actions: [
          TextButton(
            onPressed: (_saving || _draftProfile == null) ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: AppTokens.spaceL,
                    height: AppTokens.spaceL,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.pagePadding,
                AppTokens.spaceM,
                AppTokens.pagePadding,
                AppTokens.spaceXxl,
              ),
              children: [
                _BasicSection(
                  sex: _sex,
                  onSexChanged: (v) => setState(() => _sex = v),
                  ageCtrl: _ageCtrl,
                  heightCtrl: _heightCtrl,
                  weightCtrl: _weightCtrl,
                  ageError: _ageError,
                  heightError: _heightError,
                  weightError: _weightError,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: AppTokens.cardGap),
                _ActivitySection(
                  value: _activity,
                  onChanged: (v) => setState(() => _activity = v),
                ),
                const SizedBox(height: AppTokens.cardGap),
                _GoalSection(
                  goal: _goal,
                  pace: _pace,
                  targetCtrl: _targetCtrl,
                  heightCm: _height,
                  onGoalChanged: (v) => setState(() => _goal = v),
                  onPaceChanged: (v) => setState(() => _pace = v),
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: AppTokens.cardGap),
                _ResultSection(
                  profile: _draftProfile,
                  budget: _draftBudget,
                  goal: _goal,
                ),
                const SizedBox(height: AppTokens.spaceL),
                Text(
                  '计算基于 Mifflin-St Jeor 公式与通用活动系数，属于估算值，'
                  '不能替代医学建议。',
                  style: AppTokens.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }

  static String _trimNumber(double v) {
    // 62.0 → "62"，62.5 → "62.5"
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

// ---------------------------------------------------------------------------
// 分区容器
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.hint});

  final String title;
  final String? hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppTokens.borderM,
        border: Border.all(
          width: AppTokens.borderWidth,
          color: theme.colorScheme.onSurface
              .withAlpha((AppTokens.borderOpacity * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTokens.title),
          if (hint != null) ...[
            const SizedBox(height: AppTokens.spaceXs),
            Text(
              hint!,
              style: AppTokens.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.spaceM),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 基础信息
// ---------------------------------------------------------------------------

class _BasicSection extends StatelessWidget {
  const _BasicSection({
    required this.sex,
    required this.onSexChanged,
    required this.ageCtrl,
    required this.heightCtrl,
    required this.weightCtrl,
    required this.ageError,
    required this.heightError,
    required this.weightError,
    required this.onChanged,
  });

  final Sex sex;
  final ValueChanged<Sex> onSexChanged;
  final TextEditingController ageCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final String? ageError;
  final String? heightError;
  final String? weightError;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: '基础信息',
      hint: '性别和年龄决定基础代谢的系数，身高体重决定代谢总量。',
      children: [
        SegmentedButton<Sex>(
          segments: [
            for (final s in Sex.values)
              ButtonSegment<Sex>(value: s, label: Text(s.label)),
          ],
          selected: {sex},
          showSelectedIcon: false,
          onSelectionChanged: (v) => onSexChanged(v.first),
        ),
        const SizedBox(height: AppTokens.spaceL),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberField(
                controller: ageCtrl,
                label: '年龄',
                suffix: '岁',
                decimal: false,
                errorText: ageError,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: AppTokens.spaceM),
            Expanded(
              child: _NumberField(
                controller: heightCtrl,
                label: '身高',
                suffix: 'cm',
                decimal: true,
                errorText: heightError,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceM),
        _NumberField(
          controller: weightCtrl,
          label: '当前体重',
          suffix: 'kg',
          decimal: true,
          errorText: weightError,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.decimal,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String suffix;
  final bool decimal;
  final String? errorText;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [decimal ? _decimalFormatter : _intFormatter],
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        errorText: errorText,
        border: const OutlineInputBorder(borderRadius: AppTokens.borderS),
        isDense: true,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 活动水平
// ---------------------------------------------------------------------------

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.value, required this.onChanged});

  final ActivityLevel value;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Section(
      title: '日常活动水平',
      hint: '只算「日常 + 运动」的总量，运动额外的消耗可以在运动记录里补。',
      children: [
        for (final level in ActivityLevel.values)
          InkWell(
            borderRadius: AppTokens.borderS,
            onTap: () => onChanged(level),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppTokens.spaceS,
              ),
              child: Row(
                children: [
                  Icon(
                    level == value
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: AppTokens.spaceXl,
                    color: level == value
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppTokens.spaceM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(level.label, style: AppTokens.body),
                            const SizedBox(width: AppTokens.spaceS),
                            Text(
                              '×${level.factor}',
                              style: AppTokens.caption.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          level.hint,
                          style: AppTokens.caption.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 目标
// ---------------------------------------------------------------------------

class _GoalSection extends StatelessWidget {
  const _GoalSection({
    required this.goal,
    required this.pace,
    required this.targetCtrl,
    required this.heightCm,
    required this.onGoalChanged,
    required this.onPaceChanged,
    required this.onChanged,
  });

  final WeightGoal goal;
  final LossPace pace;
  final TextEditingController targetCtrl;
  final double? heightCm;
  final ValueChanged<WeightGoal> onGoalChanged;
  final ValueChanged<LossPace> onPaceChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 按 BMI 22 反推的推荐目标体重，用于输入框 placeholder
    final suggested = heightCm == null
        ? null
        : UserProfile.targetBmi *
            (heightCm! / 100.0) *
            (heightCm! / 100.0);

    return _Section(
      title: '目标',
      hint: '目标体重留空就按 BMI 22（正常区间中位）自动推荐。',
      children: [
        SegmentedButton<WeightGoal>(
          segments: [
            for (final g in WeightGoal.values)
              ButtonSegment<WeightGoal>(value: g, label: Text(g.label)),
          ],
          selected: {goal},
          showSelectedIcon: false,
          onSelectionChanged: (v) => onGoalChanged(v.first),
        ),
        if (goal == WeightGoal.lose) ...[
          const SizedBox(height: AppTokens.spaceL),
          Text('减重速度', style: AppTokens.label),
          const SizedBox(height: AppTokens.spaceS),
          SegmentedButton<LossPace>(
            segments: [
              for (final p in LossPace.values)
                ButtonSegment<LossPace>(value: p, label: Text(p.label)),
            ],
            selected: {pace},
            showSelectedIcon: false,
            onSelectionChanged: (v) => onPaceChanged(v.first),
          ),
          const SizedBox(height: AppTokens.spaceS),
          Text(
            '${pace.hint}。越快越难坚持，也越容易掉肌肉。',
            style: AppTokens.caption.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppTokens.spaceL),
        TextField(
          controller: targetCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_decimalFormatter],
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: '目标体重',
            suffixText: 'kg',
            hintText: suggested == null
                ? null
                : '推荐 ${suggested.toStringAsFixed(1)}',
            border: const OutlineInputBorder(borderRadius: AppTokens.borderS),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 结果预览
// ---------------------------------------------------------------------------

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.profile,
    required this.budget,
    required this.goal,
  });

  final UserProfile? profile;
  final CalorieBudget? budget;
  final WeightGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final p = profile;
    final b = budget;

    if (p == null || b == null) {
      return _Section(
        title: '你的每日预算',
        children: [
          Text(
            '把上面的信息填完，这里会实时算出每天该吃多少。',
            style: AppTokens.body.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final weeks = p.weeksToGoal;
    final effectiveGoal = p.effectiveGoal;

    return _Section(
      title: '你的每日预算',
      children: [
        // 主数字：建议摄入
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              b.intakeTarget.round().toString(),
              style: AppTokens.display.copyWith(color: colors.calorieOk),
            ),
            const SizedBox(width: AppTokens.spaceS),
            Text(
              'kcal / 日',
              style: AppTokens.body.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spaceL),
        _MetricRow(
          label: '基础代谢 BMR',
          value: '${b.bmr.round()} kcal',
          note: b.bmrFormula,
        ),
        _MetricRow(
          label: '每日总消耗 TDEE',
          value: '${b.tdee.round()} kcal',
          note: '${p.activity.label} ×${p.activity.factor}',
        ),
        _MetricRow(
          // 缺口为 0 时不该写「缺口 0 kcal」——读起来像没算出来。
          // 维持目标就明确说"平衡"。
          label: b.deficit > 0.5
              ? '每日热量缺口'
              : (b.deficit < -0.5 ? '每日热量盈余' : '热量收支'),
          value: b.deficit.abs() < 0.5
              ? '持平'
              : '${b.deficit.abs().round()} kcal',
          note: b.deficit.abs() < 0.5
              ? '维持当前体重'
              : '约 ${b.weeklyChangeKg.abs().toStringAsFixed(2)} kg / 周',
        ),
        const Divider(height: AppTokens.spaceXl),
        _MetricRow(
          label: '蛋白质',
          value: '${b.proteinG.round()} g',
          note: '约 ${(b.proteinG / p.weightKg).toStringAsFixed(1)} g/kg',
        ),
        _MetricRow(label: '脂肪', value: '${b.fatG.round()} g'),
        _MetricRow(label: '碳水', value: '${b.carbG.round()} g'),

        if (weeks > 0) ...[
          const Divider(height: AppTokens.spaceXl),
          _MetricRow(
            label: effectiveGoal == WeightGoal.gain ? '预计达到目标' : '预计达标用时',
            value: '$weeks 周',
            note: '目标 ${p.resolvedTargetWeight.toStringAsFixed(1)} kg'
                '（现在 ${p.weightKg.toStringAsFixed(1)} kg）',
          ),
        ],

        // 安全提示：必须是"说明"而不是"警告"，语气要平
        if (b.isFloored) ...[
          const SizedBox(height: AppTokens.spaceM),
          _Notice(
            icon: Icons.shield_outlined,
            text: '按你选的速度算出的热量低于安全下限，已自动抬到 '
                '${b.intakeTarget.round()} kcal。减得更快不等于减得更好。',
          ),
        ],
        if (effectiveGoal == WeightGoal.maintain && goal == WeightGoal.lose) ...[
          const SizedBox(height: AppTokens.spaceM),
          _Notice(
            icon: Icons.info_outline,
            text: '你的体重已经达到目标体重，当前按「维持」计算，不再制造热量缺口。',
          ),
        ],
        // 选了"增重"但默认目标（BMI 22）比现在还低 —— 这是最常见的困惑点：
        // 用户明明点了增重，结果预算不给盈余。必须解释清楚并给出动作。
        if (goal == WeightGoal.gain &&
            effectiveGoal == WeightGoal.maintain &&
            p.targetWeightKg == null) ...[
          const SizedBox(height: AppTokens.spaceM),
          _Notice(
            icon: Icons.info_outline,
            text: '按 BMI 22 推出的目标体重 '
                '${p.resolvedTargetWeight.toStringAsFixed(1)} kg 比你现在的体重还低，'
                '已按「维持」计算。想增重的话，请手动填一个更高的目标体重。',
          ),
        ],
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTokens.body),
                if (note != null)
                  Text(
                    note!,
                    style: AppTokens.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: AppTokens.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.spaceM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppTokens.borderS,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppTokens.spaceL, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.spaceS),
          Expanded(
            child: Text(
              text,
              style: AppTokens.caption.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
