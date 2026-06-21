import '../models/hourly_forecast.dart';
import '../models/kma_forecast_item.dart';

/// Fills in missing fields on partially-parsed hourly drafts so the UI never
/// has to force-unwrap a nullable value: missing 강수확률 defaults to 0,
/// missing 날씨상태(SKY/PTY) carries forward the previous hour's value.
/// An hour with no usable temperature at all (and no prior hour to carry
/// forward from) is dropped rather than guessed.
List<HourlyForecast> interpolateHourlyForecasts(List<HourlyForecastDraft> drafts) {
  final sorted = [...drafts]..sort((a, b) => a.time.compareTo(b.time));
  final result = <HourlyForecast>[];

  SkyCondition? prevSky;
  PrecipitationType? prevPty;
  double? prevTemp;

  for (final draft in sorted) {
    final sky = draft.sky ?? prevSky ?? SkyCondition.clear;
    final pty = draft.precipitationType ?? prevPty ?? PrecipitationType.none;
    final temp = draft.temperature ?? prevTemp;

    if (temp == null) {
      continue;
    }

    result.add(HourlyForecast(
      time: draft.time,
      temperature: temp,
      sky: sky,
      precipitationType: pty,
      precipitationAmount: draft.precipitationAmount ?? 0.0,
      precipitationProbability: draft.precipitationProbability ?? 0,
    ));

    prevSky = sky;
    prevPty = pty;
    prevTemp = temp;
  }

  return result;
}
