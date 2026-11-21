// lib/core/widgets/input/quick_action_sheet.dart
//
// 统一「快速记录」底部弹层：一个 sheet 内切换 体重 / 运动 / 饮食 三态，
// 避免用户为了记一件事跳三次页面。
//
// 设计约束：
//   · 内容由调用方通过 builder 注入，组件本身不含业务逻辑（AGENTS.md 禁止项）
//   · 键盘弹起时内容整体上移（viewInsets），输入框不被遮挡
//   · 触控高度 ≥48dp
//
// 用法：
//   showQuickActionSheet(context, tabs: [
//     QuickActionTab(label: '体重', icon: Icons.monitor_weight_outlined,
//         builder: (c) => const WeightQuickInput()),
//     ...
//   ]);

import 'package:flutter/material.dart';

import '../../../app/theme/app_tokens.dart';

/// 弹层内的一页。
class QuickActionTab {
  const QuickActionTab({
    required this.label,
    required this.icon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

/// 打开快速记录弹层。
///
/// 返回的 Future 在弹层关闭时完成；各页需自行通过 [Navigator.pop] 或回调关闭。
Future<void> showQuickActionSheet(
  BuildContext context, {
  required List<QuickActionTab> tabs,
  int initialIndex = 0,
  String? title,
}) {
  assert(tabs.isNotEmpty, 'QuickActionSheet 至少需要一个 tab');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTokens.radiusL),
      ),
    ),
    builder: (_) => _QuickActionSheetBody(
      tabs: tabs,
      initialIndex: initialIndex.clamp(0, tabs.length - 1),
      title: title,
    ),
  );
}

class _QuickActionSheetBody extends StatefulWidget {
  const _QuickActionSheetBody({
    required this.tabs,
    required this.initialIndex,
    this.title,
  });

  final List<QuickActionTab> tabs;
  final int initialIndex;
  final String? title;

  @override
  State<_QuickActionSheetBody> createState() => _QuickActionSheetBodyState();
}

class _QuickActionSheetBodyState extends State<_QuickActionSheetBody> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);

    return Padding(
      // 键盘弹起时整体上移
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.spaceL,
                  0,
                  AppTokens.spaceL,
                  AppTokens.spaceM,
                ),
                child: Text(
                  widget.title!,
                  style: AppTokens.title.copyWith(color: scheme.onSurface),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spaceL,
              ),
              child: _SegmentedRow(
                tabs: widget.tabs,
                selected: _index,
                onChanged: (i) => setState(() => _index = i),
              ),
            ),
            const SizedBox(height: AppTokens.spaceL),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.spaceL,
                  0,
                  AppTokens.spaceL,
                  AppTokens.spaceL,
                ),
                child: widget.tabs[_index].builder(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 自绘分段控件。
///
/// 不用 SegmentedButton 的原因：三个中文标签在窄屏会挤压换行，
/// 自绘可以保证等分、且选中态更贴近项目视觉。
class _SegmentedRow extends StatelessWidget {
  const _SegmentedRow({
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<QuickActionTab> tabs;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: AppTokens.minTouchTarget,
      padding: const EdgeInsets.all(AppTokens.spaceXs),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selected;
          return Expanded(
            child: Semantics(
              selected: active,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: AppTokens.durFast,
                  curve: AppTokens.curve,
                  decoration: BoxDecoration(
                    color: active ? scheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tabs[i].icon,
                        size: 16,
                        color: active
                            ? scheme.onSurface
                            : scheme.onSurface.withAlpha(140),
                      ),
                      const SizedBox(width: AppTokens.spaceXs),
                      Flexible(
                        child: Text(
                          tabs[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTokens.label.copyWith(
                            color: active
                                ? scheme.onSurface
                                : scheme.onSurface.withAlpha(140),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
