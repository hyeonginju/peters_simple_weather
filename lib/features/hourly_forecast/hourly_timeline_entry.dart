import '../../data/weather/models/kma_forecast_item.dart';

/// One slot in the hourly timeline — either the synthetic "지금" entry built
/// from the current snapshot, or a future hourly forecast slot.
class HourlyTimelineEntry {
  final String label;
  final DateTime time;
  final double temperature;
  final SkyCondition sky;
  final PrecipitationType precipitationType;
  final double precipitationAmount;
  final int precipitationProbability;

  const HourlyTimelineEntry({
    required this.label,
    required this.time,
    required this.temperature,
    required this.sky,
    required this.precipitationType,
    required this.precipitationAmount,
    required this.precipitationProbability,
  });
}
