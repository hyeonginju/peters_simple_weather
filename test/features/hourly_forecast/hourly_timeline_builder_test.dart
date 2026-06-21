import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/models/hourly_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';
import 'package:peters_simple_weather/data/weather/models/weather_snapshot.dart';
import 'package:peters_simple_weather/features/hourly_forecast/hourly_timeline_builder.dart';

HourlyForecast _hour(int hour, double temp) {
  return HourlyForecast(
    time: DateTime(2026, 6, 19, hour),
    temperature: temp,
    sky: SkyCondition.clear,
    precipitationType: PrecipitationType.none,
    precipitationAmount: 0,
    precipitationProbability: 10,
  );
}

void main() {
  test('첫 항목은 항상 "지금"이며 스냅샷 값을 사용함', () {
    const snapshot = WeatherSnapshot(
      temperature: 24,
      sky: SkyCondition.clear,
      precipitationType: PrecipitationType.none,
      precipitationAmount: 0,
      precipitationProbability: 10,
    );

    final timeline = buildHourlyTimeline(
      snapshot: snapshot,
      hourly: [_hour(14, 24), _hour(15, 25)],
      now: DateTime(2026, 6, 19, 14, 30),
    );

    expect(timeline.first.label, '지금');
    expect(timeline.first.temperature, 24);
  });

  test('현재 시각 이후의 시간대만 포함하고, 이전/현재 슬롯은 제외함', () {
    const snapshot = WeatherSnapshot(
      temperature: 24,
      sky: SkyCondition.clear,
      precipitationType: PrecipitationType.none,
      precipitationAmount: 0,
      precipitationProbability: 10,
    );

    final timeline = buildHourlyTimeline(
      snapshot: snapshot,
      hourly: [_hour(13, 22), _hour(14, 24), _hour(15, 25), _hour(16, 25)],
      now: DateTime(2026, 6, 19, 14, 30),
    );

    expect(timeline.map((e) => e.label).toList(), ['지금', '15시', '16시']);
  });

  test('시간 순서가 뒤섞여 들어와도 정렬됨', () {
    const snapshot = WeatherSnapshot(
      temperature: 24,
      sky: SkyCondition.clear,
      precipitationType: PrecipitationType.none,
      precipitationAmount: 0,
      precipitationProbability: 10,
    );

    final timeline = buildHourlyTimeline(
      snapshot: snapshot,
      hourly: [_hour(17, 23), _hour(15, 25)],
      now: DateTime(2026, 6, 19, 14, 30),
    );

    expect(timeline.map((e) => e.label).toList(), ['지금', '15시', '17시']);
  });

  group('hourlyDateLabel', () {
    final today = DateTime(2026, 6, 20, 9);

    test('같은 날 → "오늘 N일"', () {
      expect(hourlyDateLabel(DateTime(2026, 6, 20, 23), today: today), '오늘 20일');
    });

    test('다음 날(0시 포함) → "내일 N일"', () {
      expect(hourlyDateLabel(DateTime(2026, 6, 21, 0), today: today), '내일 21일');
    });

    test('이틀 뒤 → "모레 N일"', () {
      expect(hourlyDateLabel(DateTime(2026, 6, 22, 12), today: today), '모레 22일');
    });

    test('사흘 이상 → "M월 N일"', () {
      expect(hourlyDateLabel(DateTime(2026, 6, 23, 12), today: today), '6월 23일');
    });
  });
}
