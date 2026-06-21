import 'package:freezed_annotation/freezed_annotation.dart';

import 'daily_forecast.dart';
import 'hourly_forecast.dart';
import 'weather_snapshot.dart';

part 'forecast_result.freezed.dart';

/// Three-way outcome of fetching a region's weather: a clean success, a
/// partial failure where some sub-fetch (hourly/daily) failed but the rest
/// is usable, or a total failure where nothing is renderable.
@freezed
sealed class ForecastResult with _$ForecastResult {
  const factory ForecastResult.success({
    required WeatherSnapshot snapshot,
    required List<HourlyForecast> hourly,
    required List<DailyForecast> daily,
  }) = ForecastSuccess;

  const factory ForecastResult.partialFailure({
    required WeatherSnapshot snapshot,
    List<HourlyForecast>? hourly,
    List<DailyForecast>? daily,
  }) = ForecastPartialFailure;

  const factory ForecastResult.failure(String message) = ForecastFailure;
}
