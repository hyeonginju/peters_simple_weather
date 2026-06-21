import 'kma_forecast_item.dart';

/// One day's forecast card, regardless of whether it was derived from the
/// short-term (day 1-3) or mid-term (day 4-10) KMA endpoints.
class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final int popPercent;
  final SkyCondition? sky;
  final PrecipitationType? precipitationType;

  const DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.popPercent,
    this.sky,
    this.precipitationType,
  });
}

/// One day's row already extracted from getMidLandFcst (AM/PM 강수확률,
/// 날씨 텍스트) and getMidTa (최저/최고 기온) — the merger's day-4~10 input
/// contract.
class MidTermDayForecast {
  final DateTime date;
  final int amPopPercent;
  final int pmPopPercent;
  final double minTemp;
  final double maxTemp;
  final SkyCondition? sky;
  final PrecipitationType? precipitationType;

  const MidTermDayForecast({
    required this.date,
    required this.amPopPercent,
    required this.pmPopPercent,
    required this.minTemp,
    required this.maxTemp,
    this.sky,
    this.precipitationType,
  });
}
