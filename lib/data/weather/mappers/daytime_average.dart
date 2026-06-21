import '../models/hourly_forecast.dart';

/// 추천 옷차림 산출용 낮 시간대(09-18시) 평균 기온. 소수점 첫째 자리에서
/// 반올림한다 (기획서 2.3).
double? computeDaytimeAverageTemp(List<HourlyForecast> hourly, DateTime date) {
  final daytimeTemps = hourly
      .where((h) =>
          h.time.year == date.year &&
          h.time.month == date.month &&
          h.time.day == date.day &&
          h.time.hour >= 9 &&
          h.time.hour <= 18)
      .map((h) => h.temperature)
      .toList();

  if (daytimeTemps.isEmpty) {
    return null;
  }

  final average = daytimeTemps.reduce((a, b) => a + b) / daytimeTemps.length;
  return average.roundToDouble();
}
