// lib/app/theme/app_colors.dart
//
// 语义色（Semantic Colors）——扩展 Material 的 ColorScheme。
//
// 为什么要单独一层：
//   ColorScheme 只有 primary/secondary/error 这类通用语义。
//   健康类应用需要的是「经期 / 易孕 / 排卵 / 热量 / 体重」这种业务语义。
//   如果直接把这些写成 Color(0xFF...)，深浅色两套值会散落在几十个文件里。
//
// 核心原则（见可行性计划书 ADR-3）：
//   颜色表达「状态」，不表达「对错」。
//   —— 体重上升用中性灰，绝不用红；红色只留给破坏性操作。

import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.period,
    required this.fertile,
    required this.ovulation,
    required this.predicted,
    required this.calorieOk,
    required this.calorieOver,
    required this.weightDown,
    required this.weightUp,
    required this.danger,
    required this.track,
    required this.grid,
    required this.brand,
    required this.brandSoft,
    required this.heroStart,
    required this.heroEnd,
    required this.surface,
    required this.pageBg,
    required this.shadow,
    required this.exercise,
  });

  /// 经期。生理语义，用红不构成负面暗示。
  final Color period;

  /// 易孕期。
  final Color fertile;

  /// 排卵日。
  final Color ovulation;

  /// 预测值。必须与「已记录」在视觉上可区分（配合虚线使用）。
  final Color predicted;

  /// 热量在预算内。
  final Color calorieOk;

  /// 超出预算。**刻意不用红色**，避免焦虑。
  final Color calorieOver;

  /// 体重下降（减脂场景下为正向）。
  final Color weightDown;

  /// 体重上升。**中性灰，不是红色**（ADR-3）。
  final Color weightUp;

  /// 仅用于破坏性操作（删除记录、清空数据）。**不得用于任何数据展示**。
  final Color danger;

  /// 环形/条形进度条的底轨。
  final Color track;

  /// 图表网格线。
  final Color grid;

  // ---------------- 界面层（2026-11 视觉升级新增） ----------------
  //
  // 这五个不是「业务语义」，而是「界面语义」。仍然放在这里而不是散到页面里，
  // 理由同 R10：深浅色两套值必须只有一个来源，否则改主题要改几十个文件。

  /// 品牌强调色：渐变按钮、强调条、选中态。
  final Color brand;

  /// 品牌浅底：胶囊标签背景、图标底色（浅色下是淡玫瑰，深色下是暗玫瑰）。
  final Color brandSoft;

  /// 首屏渐变头的起止色。必须成对使用。
  final Color heroStart;
  final Color heroEnd;

  /// 卡片表面。浅色纯白、深色比 pageBg 略亮一档，卡片才有层次。
  final Color surface;

  /// 页面底色。浅色是极淡玫瑰灰，让白卡浮起来；深色接近纯黑。
  final Color pageBg;

  /// 卡片投影色（已带透明度，直接给 BoxShadow 用）。
  final Color shadow;

  /// 运动消耗（热量环的内圈弧、运动相关强调）。
  ///
  /// 为什么不用 fertile：fertile 与 calorieOk 都是绿色，两条弧画在同一张环上
  /// 分不出来（2026-11 走查实测）。运动用蓝，与绿（摄入）/橙（超标）都不撞。
  final Color exercise;

  // ---------------- 浅色 ----------------
  static const AppColors light = AppColors(
    period: Color(0xFFE4586F),
    fertile: Color(0xFF2FA36B),
    ovulation: Color(0xFF7B5BD6),
    predicted: Color(0x4DE4586F),
    calorieOk: Color(0xFF2FA36B),
    calorieOver: Color(0xFFE08A2E),
    weightDown: Color(0xFF2FA36B),
    weightUp: Color(0xFF8A94A6),
    danger: Color(0xFFC62828),
    track: Color(0x14202A3A),
    grid: Color(0x1F202A3A),
    brand: Color(0xFFD8475F),
    brandSoft: Color(0xFFFFEDF0),
    heroStart: Color(0xFFF98A9B),
    heroEnd: Color(0xFFE4586F),
    surface: Color(0xFFFFFFFF),
    pageBg: Color(0xFFFFF7F8),
    shadow: Color(0x1A202A3A),
    exercise: Color(0xFF2F7FB8),
  );

  // ---------------- 深色 ----------------
  // 保持色相不变，饱和度略降，避免深色下刺眼。
  static const AppColors dark = AppColors(
    period: Color(0xFFF07C90),
    fertile: Color(0xFF4FBF89),
    ovulation: Color(0xFF9B82E6),
    predicted: Color(0x59F07C90),
    calorieOk: Color(0xFF4FBF89),
    calorieOver: Color(0xFFF0A452),
    weightDown: Color(0xFF4FBF89),
    weightUp: Color(0xFF9AA4B4),
    danger: Color(0xFFE05252),
    track: Color(0x1FFFFFFF),
    grid: Color(0x14FFFFFF),
    brand: Color(0xFFF07C90),
    brandSoft: Color(0xFF3A2228),
    heroStart: Color(0xFF6B2733),
    heroEnd: Color(0xFF3E171F),
    surface: Color(0xFF161B20),
    pageBg: Color(0xFF0E1216),
    shadow: Color(0x66000000),
    exercise: Color(0xFF63AEE0),
  );

  /// 取当前主题下的语义色。若 Theme 未挂载（如 ErrorWidget），回退浅色。
  static AppColors of(BuildContext context) {
    final ext = Theme.of(context).extension<AppColors>();
    return ext ?? light;
  }

  @override
  AppColors copyWith({
    Color? period,
    Color? fertile,
    Color? ovulation,
    Color? predicted,
    Color? calorieOk,
    Color? calorieOver,
    Color? weightDown,
    Color? weightUp,
    Color? danger,
    Color? track,
    Color? grid,
    Color? brand,
    Color? brandSoft,
    Color? heroStart,
    Color? heroEnd,
    Color? surface,
    Color? pageBg,
    Color? shadow,
    Color? exercise,
  }) {
    return AppColors(
      period: period ?? this.period,
      fertile: fertile ?? this.fertile,
      ovulation: ovulation ?? this.ovulation,
      predicted: predicted ?? this.predicted,
      calorieOk: calorieOk ?? this.calorieOk,
      calorieOver: calorieOver ?? this.calorieOver,
      weightDown: weightDown ?? this.weightDown,
      weightUp: weightUp ?? this.weightUp,
      danger: danger ?? this.danger,
      track: track ?? this.track,
      grid: grid ?? this.grid,
      brand: brand ?? this.brand,
      brandSoft: brandSoft ?? this.brandSoft,
      heroStart: heroStart ?? this.heroStart,
      heroEnd: heroEnd ?? this.heroEnd,
      surface: surface ?? this.surface,
      pageBg: pageBg ?? this.pageBg,
      shadow: shadow ?? this.shadow,
      exercise: exercise ?? this.exercise,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      period: Color.lerp(period, other.period, t)!,
      fertile: Color.lerp(fertile, other.fertile, t)!,
      ovulation: Color.lerp(ovulation, other.ovulation, t)!,
      predicted: Color.lerp(predicted, other.predicted, t)!,
      calorieOk: Color.lerp(calorieOk, other.calorieOk, t)!,
      calorieOver: Color.lerp(calorieOver, other.calorieOver, t)!,
      weightDown: Color.lerp(weightDown, other.weightDown, t)!,
      weightUp: Color.lerp(weightUp, other.weightUp, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      track: Color.lerp(track, other.track, t)!,
      grid: Color.lerp(grid, other.grid, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      heroStart: Color.lerp(heroStart, other.heroStart, t)!,
      heroEnd: Color.lerp(heroEnd, other.heroEnd, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      pageBg: Color.lerp(pageBg, other.pageBg, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      exercise: Color.lerp(exercise, other.exercise, t)!,
    );
  }

  /// 供单测断言用：所有字段必须非 null 且非全透明。
  List<Color> get all => [
        period,
        fertile,
        ovulation,
        predicted,
        calorieOk,
        calorieOver,
        weightDown,
        weightUp,
        danger,
        track,
        grid,
        brand,
        brandSoft,
        heroStart,
        heroEnd,
        surface,
        pageBg,
        shadow,
        exercise,
      ];
}

/// 便捷访问：`context.colors.period`
///
/// 注意命名不要与 Material 的 `context.colorScheme` 混淆。
extension AppColorsX on BuildContext {
  AppColors get colors => AppColors.of(this);
}


