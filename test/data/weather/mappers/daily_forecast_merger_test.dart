import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/mappers/daily_forecast_merger.dart';
import 'package:peters_simple_weather/data/weather/models/daily_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/hourly_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';

HourlyForecast _hour(int day, int hour, double temp, {int pop = 0, SkyCondition sky = SkyCondition.clear}) {
  return HourlyForecast(
    time: DateTime(2026, 6, day, hour),
    temperature: temp,
    sky: sky,
    precipitationType: PrecipitationType.none,
    precipitationAmount: 0,
    precipitationProbability: pop,
  );
}

void main() {
  group('groupDailyFromHourly', () {
    test('같은 날짜의 시간별 데이터에서 최저/최고 기온과 최대 강수확률을 추출함', () {
      final result = groupDailyFromHourly([
        _hour(19, 9, 18, pop: 10),
        _hour(19, 14, 24, pop: 30),
        _hour(19, 18, 21, pop: 20),
      ]);

      expect(result, hasLength(1));
      expect(result.single.minTemp, 18);
      expect(result.single.maxTemp, 24);
      expect(result.single.popPercent, 30);
    });

    test('날짜가 다르면 별도 일자로 분리되고 날짜순 정렬됨', () {
      final result = groupDailyFromHourly([
        _hour(20, 14, 25),
        _hour(19, 14, 24),
      ]);

      expect(result, hasLength(2));
      expect(result[0].date.day, 19);
      expect(result[1].date.day, 20);
    });
  });

  group('mergeDailyForecasts', () {
    test('단기예보(1~3일)와 중기예보(4~10일)가 날짜순으로 이어붙여짐', () {
      final shortTerm = [
        DailyForecast(date: DateTime(2026, 6, 19), minTemp: 18, maxTemp: 29, popPercent: 10),
        DailyForecast(date: DateTime(2026, 6, 20), minTemp: 19, maxTemp: 28, popPercent: 20),
      ];
      final midTerm = [
        MidTermDayForecast(date: DateTime(2026, 6, 21), amPopPercent: 70, pmPopPercent: 50, minTemp: 20, maxTemp: 26),
      ];

      final result = mergeDailyForecasts(shortTerm, midTerm);

      expect(result, hasLength(3));
      expect(result.map((d) => d.date.day), [19, 20, 21]);
      expect(result.last.popPercent, 70);
      expect(result.last.minTemp, 20);
      expect(result.last.maxTemp, 26);
    });

    test('날짜가 겹치면 단기예보 데이터가 우선함', () {
      final shortTerm = [
        DailyForecast(date: DateTime(2026, 6, 19), minTemp: 18, maxTemp: 29, popPercent: 10),
      ];
      final midTerm = [
        MidTermDayForecast(date: DateTime(2026, 6, 19), amPopPercent: 90, pmPopPercent: 90, minTemp: 0, maxTemp: 0),
      ];

      final result = mergeDailyForecasts(shortTerm, midTerm);

      expect(result, hasLength(1));
      expect(result.single.minTemp, 18);
      expect(result.single.popPercent, 10);
    });
  });
}
