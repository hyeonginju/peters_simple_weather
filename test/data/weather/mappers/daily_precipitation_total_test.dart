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

  test('실측 누적값 + 현재 시각 이후 예보 강수량만 합산함', () {
    final hourly = [_hour(9, 1.0), _hour(14, 2.5), _hour(18, 0.5)];
    final now = DateTime(2026, 6, 19, 14, 30);
    expect(mergeTodayPrecipitationTotal(3.0, hourly, now), 6.0); // 3.0(실측) + 2.5(14시) + 0.5(18시)
  });

  test('현재 시각보다 이전 시간대의 예보값은 이중 계산하지 않음', () {
    final hourly = [_hour(9, 1.0), _hour(14, 2.5)];
    final now = DateTime(2026, 6, 19, 14, 30);
    expect(mergeTodayPrecipitationTotal(0.0, hourly, now), 2.5); // 9시 예보값은 실측으로 대체되므로 제외
  });

  test('다른 날짜의 예보 강수량은 합산에서 제외함(merge)', () {
    final hourly = [_hour(9, 1.0), _hour(14, 5.0, day: 20)];
    final now = DateTime(2026, 6, 19, 8, 0);
    expect(mergeTodayPrecipitationTotal(0.0, hourly, now), 1.0);
  });

  test('실측값만 있고 남은 예보가 없어도 그대로 반환함', () {
    expect(mergeTodayPrecipitationTotal(4.2, [], DateTime(2026, 6, 19, 14, 30)), 4.2);
  });
}
