import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/mappers/weather_interpolator.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';

HourlyForecastDraft _draft(
  int hour, {
  double? temperature,
  SkyCondition? sky,
  PrecipitationType? precipitationType,
  double? precipitationAmount,
  int? precipitationProbability,
}) {
  final draft = HourlyForecastDraft(time: DateTime(2026, 6, 19, hour))
    ..temperature = temperature
    ..sky = sky
    ..precipitationType = precipitationType
    ..precipitationAmount = precipitationAmount
    ..precipitationProbability = precipitationProbability;
  return draft;
}

void main() {
  test('누락된 강수확률(POP)은 0으로 기본값 처리됨', () {
    final result = interpolateHourlyForecasts([
      _draft(14, temperature: 24, sky: SkyCondition.clear, precipitationType: PrecipitationType.none),
    ]);

    expect(result.single.precipitationProbability, 0);
  });

  test('누락된 SKY/PTY는 이전 시간대 값을 carry-forward함', () {
    final result = interpolateHourlyForecasts([
      _draft(14, temperature: 24, sky: SkyCondition.cloudy, precipitationType: PrecipitationType.rain),
      _draft(15, temperature: 23),
    ]);

    expect(result[1].sky, SkyCondition.cloudy);
    expect(result[1].precipitationType, PrecipitationType.rain);
  });

  test('첫 시간대부터 SKY/PTY가 누락되면 맑음/무강수 기본값 사용', () {
    final result = interpolateHourlyForecasts([
      _draft(14, temperature: 24),
    ]);

    expect(result.single.sky, SkyCondition.clear);
    expect(result.single.precipitationType, PrecipitationType.none);
  });

  test('기온이 없고 이전 시간대도 없으면 해당 시간은 드롭됨', () {
    final result = interpolateHourlyForecasts([
      _draft(14),
      _draft(15, temperature: 23),
    ]);

    expect(result, hasLength(1));
    expect(result.single.time.hour, 15);
  });

  test('기온이 누락되면 이전 시간대 기온을 carry-forward함', () {
    final result = interpolateHourlyForecasts([
      _draft(14, temperature: 24),
      _draft(15),
    ]);

    expect(result[1].temperature, 24);
  });

  test('입력이 비어있으면 빈 리스트를 반환함', () {
    expect(interpolateHourlyForecasts([]), isEmpty);
  });
}
