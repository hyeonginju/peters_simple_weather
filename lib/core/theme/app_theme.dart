import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Pretendard';

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      brightness: brightness,
      surface: palette.surface,
      primary: palette.point,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.surface,
      fontFamily: fontFamily,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: palette.textPrimary,
        ),
      ),
      extensions: [palette],
    );
  }
}
