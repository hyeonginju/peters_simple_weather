import '../models/daily_forecast.dart';
import '../models/hourly_forecast.dart';
import '../models/kma_forecast_item.dart';

/// Most-severe-wins precipitation type for a day with mixed hourly readings.
const _precipitationSeverity = [
  PrecipitationType.none,
  PrecipitationType.shower,
  PrecipitationType.rain,
  PrecipitationType.rainAndSnow,
  PrecipitationType.snow,
];

PrecipitationType _mostSevere(Iterable<PrecipitationType> types) {
  return types.reduce(
    (a, b) => _precipitationSeverity.indexOf(b) > _precipitationSeverity.indexOf(a) ? b : a,
  );
}

/// Derives day 0-3 daily cards from the short-term hourly forecast by
/// grouping per calendar date: min/max of TMP, and the day's highest 강수확률
/// as the representative risk figure.
///
/// getVilageFcst's reliable window is today~+3 days, but it occasionally
/// spills 1-2 trailing hours into day+4 (e.g. just the 00:00 row). Without a
/// cutoff that lone hour gets treated as a whole day, producing a flat
/// min==max card that then wins over the real (and more complete) mid-term
/// forecast for that date in [mergeDailyForecasts]. `now` lets us drop any
/// date past the +3-day window mid-term is responsible for.
List<DailyForecast> groupDailyFromHourly(List<HourlyForecast> hourly, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final byDate = <DateTime, List<HourlyForecast>>{};

  for (final hour in hourly) {
    final date = DateTime(hour.time.year, hour.time.month, hour.time.day);
    if (date.difference(today).inDays > 3) continue;
    byDate.putIfAbsent(date, () => []).add(hour);
  }

  final dates = byDate.keys.toList()..sort();
  return [
    for (final date in dates)
      DailyForecast(
        date: date,
        minTemp: byDate[date]!.map((h) => h.temperature).reduce((a, b) => a < b ? a : b),
        maxTemp: byDate[date]!.map((h) => h.temperature).reduce((a, b) => a > b ? a : b),
        popPercent: byDate[date]!.map((h) => h.precipitationProbability).reduce((a, b) => a > b ? a : b),
        sky: byDate[date]!.first.sky,
        precipitationType: _mostSevere(byDate[date]!.map((h) => h.precipitationType)),
      ),
  ];
}

/// Concatenates day 1-3 (단기예보 derived) with day 4-10 (중기예보 derived)
/// into one continuous weekly list. Short-term wins on any overlapping date.
List<DailyForecast> mergeDailyForecasts(
  List<DailyForecast> shortTerm,
  List<MidTermDayForecast> midTerm,
) {
  final byDate = <DateTime, DailyForecast>{};

  for (final day in shortTerm) {
    byDate[day.date] = day;
  }

  for (final day in midTerm) {
    byDate.putIfAbsent(
      day.date,
      () => DailyForecast(
        date: day.date,
        minTemp: day.minTemp,
        maxTemp: day.maxTemp,
        popPercent: day.amPopPercent > day.pmPopPercent ? day.amPopPercent : day.pmPopPercent,
        sky: day.sky,
        precipitationType: day.precipitationType,
      ),
    );
  }

  final dates = byDate.keys.toList()..sort();
  return [for (final date in dates) byDate[date]!];
}
