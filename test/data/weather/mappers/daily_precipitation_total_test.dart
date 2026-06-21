import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/mappers/daily_precipitation_total.dart';
import 'package:peters_simple_weather/data/weather/models/hourly_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';

HourlyForecast _hour(int hour, double precip, {int day = 19}) {
  return HourlyForecast(
    time: DateTime(2026, 6, day, hour),
    temperature: 20,
    sky: SkyCondition.cloudy,
    precipitationType: PrecipitationType.rain,
    precipitationAmount: precip,
    precipitationProbability: 50,
  );
}

void main() {
  test('해당 날짜의 시간별 강수량을 모두 합산함', () {
    final hourly = [_hour(9, 1.0), _hour(14, 2.5), _hour(18, 0.5)];
    expect(sumPrecipitationToday(hourly, DateTime(2026, 6, 19)), 4.0);
  });

  test('다른 날짜의 강수량은 합산에서 제외함', () {
    final hourly = [_hour(9, 1.0), _hour(14, 5.0, day: 20)];
    expect(sumPrecipitationToday(hourly, DateTime(2026, 6, 19)), 1.0);
  });
}
