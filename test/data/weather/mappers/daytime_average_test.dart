import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/mappers/daytime_average.dart';
import 'package:peters_simple_weather/data/weather/models/hourly_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';

HourlyForecast _hour(int hour, double temp) {
  return HourlyForecast(
    time: DateTime(2026, 6, 19, hour),
    temperature: temp,
    sky: SkyCondition.clear,
    precipitationType: PrecipitationType.none,
    precipitationAmount: 0,
    precipitationProbability: 0,
  );
}

void main() {
  test('09~18시 데이터만 평균에 포함하고 반올림함', () {
    final hourly = [
      _hour(6, 100), // 범위 밖, 제외되어야 함
      _hour(9, 18),
      _hour(14, 24),
      _hour(18, 23),
      _hour(20, 100), // 범위 밖, 제외되어야 함
    ];

    final average = computeDaytimeAverageTemp(hourly, DateTime(2026, 6, 19));

    expect(average, 22); // (18+24+23)/3 = 21.67 → 반올림 22
  });

  test('해당 날짜의 09~18시 데이터가 없으면 null', () {
    final hourly = [_hour(20, 24)];
    expect(computeDaytimeAverageTemp(hourly, DateTime(2026, 6, 19)), isNull);
  });

  test('다른 날짜의 데이터는 포함하지 않음', () {
    final hourly = [
      HourlyForecast(
        time: DateTime(2026, 6, 20, 14),
        temperature: 30,
        sky: SkyCondition.clear,
        precipitationType: PrecipitationType.none,
        precipitationAmount: 0,
        precipitationProbability: 0,
      ),
      _hour(14, 20),
    ];

    expect(computeDaytimeAverageTemp(hourly, DateTime(2026, 6, 19)), 20);
  });
}
