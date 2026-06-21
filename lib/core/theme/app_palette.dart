import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Semantic, theme-aware color tokens. Widgets read these via
/// `Theme.of(context).extension<AppPalette>()!` (or the `context.palette`
/// getter) so the same widget code renders correctly in light and dark.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.surface,
    required this.card,
    required this.cardBorder,
    required this.divider,
    required this.searchBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.point,
    required this.pointText,
    required this.pointBg,
    required this.dotInactive,
    required this.danger,
    required this.dangerBg,
    required this.rain,
    required this.chartHigh,
    required this.chartLow,
    required this.chartBand,
  });

  final Color surface;
  final Color card;
  final Color cardBorder;
  final Color divider;
  final Color searchBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color point;
  final Color pointText;
  final Color pointBg;
  final Color dotInactive;
  final Color danger;
  final Color dangerBg;
  final Color rain;
  final Color chartHigh;
  final Color chartLow;
  final Color chartBand;

  static const light = AppPalette(
    surface: AppColors.lightSurface,
    card: AppColors.cardLight,
    cardBorder: AppColors.cardBorderLight,
    divider: AppColors.dividerLight,
    searchBg: AppColors.searchBgLight,
    textPrimary: AppColors.textPrimaryLight,
    textSecondary: AppColors.textSecondaryLight,
    textMuted: AppColors.textMutedLight,
    textFaint: AppColors.textFaintLight,
    point: AppColors.indigo,
    pointText: AppColors.indigoText,
    pointBg: AppColors.indigoBg,
    dotInactive: AppColors.dotInactiveLight,
    danger: AppColors.danger,
    dangerBg: AppColors.dangerBgLight,
    rain: AppColors.rain,
    chartHigh: AppColors.chartHigh,
    chartLow: AppColors.chartLow,
    chartBand: AppColors.chartBand,
  );

  static const dark = AppPalette(
    surface: AppColors.darkSurface,
    card: AppColors.cardDark,
    cardBorder: Color(0x0FFFFFFF), // rgba(255,255,255,.06)
    divider: Color(0x14FFFFFF),
    searchBg: AppColors.searchBgDark,
    textPrimary: AppColors.textPrimaryDark,
    textSecondary: AppColors.textSecondaryDark,
    textMuted: AppColors.textMutedDark,
    textFaint: AppColors.textFaintDark,
    point: AppColors.indigoDark,
    pointText: AppColors.indigoTextDark,
    pointBg: AppColors.indigoBgDark,
    dotInactive: AppColors.dotInactiveDark,
    danger: AppColors.danger,
    dangerBg: AppColors.dangerBgDark,
    rain: AppColors.rain,
    chartHigh: AppColors.chartHigh,
    chartLow: AppColors.chartLow,
    chartBand: AppColors.chartBand,
  );

  @override
  AppPalette copyWith({
    Color? surface,
    Color? card,
    Color? cardBorder,
    Color? divider,
    Color? searchBg,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textFaint,
    Color? point,
    Color? pointText,
    Color? pointBg,
    Color? dotInactive,
    Color? danger,
    Color? dangerBg,
    Color? rain,
    Color? chartHigh,
    Color? chartLow,
    Color? chartBand,
  }) {
    return AppPalette(
      surface: surface ?? this.surface,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      divider: divider ?? this.divider,
      searchBg: searchBg ?? this.searchBg,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      point: point ?? this.point,
      pointText: pointText ?? this.pointText,
      pointBg: pointBg ?? this.pointBg,
      dotInactive: dotInactive ?? this.dotInactive,
      danger: danger ?? this.danger,
      dangerBg: dangerBg ?? this.dangerBg,
      rain: rain ?? this.rain,
      chartHigh: chartHigh ?? this.chartHigh,
      chartLow: chartLow ?? this.chartLow,
      chartBand: chartBand ?? this.chartBand,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      searchBg: Color.lerp(searchBg, other.searchBg, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      point: Color.lerp(point, other.point, t)!,
      pointText: Color.lerp(pointText, other.pointText, t)!,
      pointBg: Color.lerp(pointBg, other.pointBg, t)!,
      dotInactive: Color.lerp(dotInactive, other.dotInactive, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      rain: Color.lerp(rain, other.rain, t)!,
      chartHigh: Color.lerp(chartHigh, other.chartHigh, t)!,
      chartLow: Color.lerp(chartLow, other.chartLow, t)!,
      chartBand: Color.lerp(chartBand, other.chartBand, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
