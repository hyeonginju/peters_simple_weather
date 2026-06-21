import 'package:flutter/material.dart';

/// Raw palette extracted verbatim from the Claude Design handoff
/// (`CleanWeather.dc.html`). Widgets should generally read semantic tokens
/// from [AppPalette] (the ThemeExtension) rather than these raw values.
class AppColors {
  AppColors._();

  // Brand
  static const indigo = Color(0xFF3E63DD);
  static const indigoDark = Color(0xFF6E8BF5); // point on dark surface
  static const indigoText = Color(0xFF3E63DD);
  static const indigoTextDark = Color(0xFF94A8F7); // badge text on dark
  static const indigoBg = Color(0xFFEAEEFC); // badge / highlight bg (light)
  static const indigoBgDark = Color(0xFF232A3D); // badge / highlight bg (dark)

  // Surfaces
  static const lightSurface = Color(0xFFF5F6F8);
  static const darkSurface = Color(0xFF121316);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1B1D21);

  // Borders / dividers
  static const cardBorderLight = Color(0xFFEFF0F3);
  static const dividerLight = Color(0xFFF1F2F5);
  static const searchBgLight = Color(0xFFF1F2F5);
  static const searchBgDark = Color(0xFF26282D);

  // Text (light)
  static const textPrimaryLight = Color(0xFF16181C);
  static const textSecondaryLight = Color(0xFF5C6066);
  static const textMutedLight = Color(0xFF9AA0A8);
  static const textFaintLight = Color(0xFFC2C6CD);

  // Text (dark)
  static const textPrimaryDark = Color(0xFFECEEF1);
  static const textSecondaryDark = Color(0xFF9CA1A8);
  static const textMutedDark = Color(0xFF6A6F77);
  static const textFaintDark = Color(0xFF4A4F57);

  // Page dots
  static const dotInactiveLight = Color(0xFFCFD3DA);
  static const dotInactiveDark = Color(0xFF3A3F47);

  // Danger (delete / error)
  static const danger = Color(0xFFD4564B);
  static const dangerBgLight = Color(0xFFFBE9E9);
  static const dangerBgDark = Color(0xFF3A2522);

  // Accents
  static const rain = Color(0xFF5B86E0); // 강수확률 / mm text
  static const chartHigh = Color(0xFFEFA23C);
  static const chartLow = Color(0xFF86A9D0);
  static const chartBand = Color(0x1F78A0D2); // rgba(120,160,210,.12)

  // Weather-icon palette (from WeatherIcon.dc.html)
  static const sunCoreTop = Color(0xFFFFD37C);
  static const sunCoreBottom = Color(0xFFF2A235);
  static const sunRay = Color(0xFFF2A93C);
  static const cloudA = Color(0xFFAEB7C4);
  static const cloudB = Color(0xFFBCC4D0);
  static const cloudC = Color(0xFFC5CCD7);
  static const cloudRainA = Color(0xFF97A0AF);
  static const cloudRainB = Color(0xFFA6AEBC);
  static const cloudRainC = Color(0xFFB0B8C6);
  static const rainDrop = Color(0xFF5B86E0);
  static const snowFlake = Color(0xFF9FB6D8);
}
