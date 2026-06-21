enum SkyCondition { clear, partlyCloudy, cloudy }

enum PrecipitationType { none, rain, rainAndSnow, snow, shower }

SkyCondition skyConditionFromCode(String code) {
  switch (code) {
    case '1':
      return SkyCondition.clear;
    case '3':
      return SkyCondition.partlyCloudy;
    case '4':
      return SkyCondition.cloudy;
    default:
      return SkyCondition.clear;
  }
}

PrecipitationType precipitationTypeFromCode(String code) {
  switch (code) {
    case '1':
      return PrecipitationType.rain;
    case '2':
      return PrecipitationType.rainAndSnow;
    case '3':
      return PrecipitationType.snow;
    case '4':
      return PrecipitationType.shower;
    default:
      return PrecipitationType.none;
  }
}

/// One row of KMA's flat, category-based forecast response
/// (e.g. `{category: "TMP", fcstDate: "20260619", fcstTime: "1400", fcstValue: "24"}`).
class KmaForecastItem {
  final String category;
  final String fcstDate;
  final String fcstTime;
  final String fcstValue;

  const KmaForecastItem({
    required this.category,
    required this.fcstDate,
    required this.fcstTime,
    required this.fcstValue,
  });
}

/// Mutable, partially-filled hourly slot produced by grouping
/// [KmaForecastItem]s before [WeatherInterpolator] fills in defaults.
class HourlyForecastDraft {
  final DateTime time;
  double? temperature;
  SkyCondition? sky;
  PrecipitationType? precipitationType;
  double? precipitationAmount;
  int? precipitationProbability;

  HourlyForecastDraft({required this.time});
}
