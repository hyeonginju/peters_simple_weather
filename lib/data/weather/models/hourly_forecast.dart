import 'kma_forecast_item.dart';

/// Fully-resolved hourly forecast slot, ready for UI consumption — no
/// nullable weather fields, since [WeatherInterpolator] has already
/// injected defaults/carried-forward values.
class HourlyForecast {
  final DateTime time;
  final double temperature;
  final SkyCondition sky;
  final PrecipitationType precipitationType;
  final double precipitationAmount;
  final int precipitationProbability;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.sky,
    required this.precipitationType,
    required this.precipitationAmount,
    required this.precipitationProbability,
  });
}
