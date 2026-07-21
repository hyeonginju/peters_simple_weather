import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/mappers/daily_forecast_merger.dart';
import 'package:peters_simple_weather/data/weather/models/daily_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/hourly_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';

HourlyForecast _hour(
  int day,
  int hour,
  double temp, {
  int pop = 0,
  double rain = 0,
  SkyCondition sky = SkyCondition.clear,
}) {
  return HourlyForecast(
    time: DateTime(2026, 6, day, hour),
    temperature: temp,
    sky: sky,
    precipitationType: PrecipitationType.none,
    precipitationAmount: rain,
    precipitationProbability: pop,
  );
}

void main() {
  group('groupDailyFromHourly', () {
    final now = DateTime(2026, 6, 19, 14, 30);

    test('같은 날짜의 시간별 데이터에서 최저/최고 기온과 최대 강수확률을 추출함', () {
      final result = groupDailyFromHourly([
        _hour(19, 9, 18, pop: 10),
        _hour(19, 14, 24, pop: 30),
        _hour(19, 18, 21, pop: 20),
      ], now);

      expect(result, hasLength(1));
      expect(result.single.minTemp, 18);
      expect(result.single.maxTemp, 24);
      expect(result.single.popPercent, 30);
    });

    test('오전(0~11)·오후(12~23) 강수확률 최댓값과 하루 총 강수량을 채움', () {
      final result = groupDailyFromHourly([
        _hour(19, 9, 18, pop: 40, rain: 1.5),
        _hour(19, 10, 19, pop: 20, rain: 0.5),
        _hour(19, 14, 24, pop: 60, rain: 2.0),
        _hour(19, 18, 21, pop: 30, rain: 0),
      ], now);

      expect(result.single.amPop, 40); // 오전 최댓값
      expect(result.single.pmPop, 60); // 오후 최댓값
      expect(result.single.precipTotalMm, closeTo(4.0, 1e-9));
    });

    test('오전 시간대가 없으면 amPop은 null', () {
      final result = groupDailyFromHourly([
        _hour(19, 15, 24, pop: 50),
      ], now);

      expect(result.single.amPop, isNull);
      expect(result.single.pmPop, 50);
    });

    test('날짜가 다르면 별도 일자로 분리되고 날짜순 정렬됨', () {
      final result = groupDailyFromHourly([
        _hour(20, 14, 25),
        _hour(19, 14, 24),
      ], now);

      expect(result, hasLength(2));
      expect(result[0].date.day, 19);
      expect(result[1].date.day, 20);
    });

    test('오늘+3일을 넘는 날짜는 제외함(단기예보 API의 꼬리 스필오버 방어)', () {
      final result = groupDailyFromHourly([
        _hour(19, 14, 24),
        _hour(20, 14, 25),
        _hour(21, 14, 26),
        _hour(22, 14, 27),
        _hour(23, 0, 19),
      ], now);

      expect(result.map((d) => d.date.day), [19, 20, 21, 22]);
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
      // 중기예보 유래일은 오전/오후 강수확률을 그대로 담고, 강수량은 데이터가 없어 null.
      expect(result.last.amPop, 70);
      expect(result.last.pmPop, 50);
      expect(result.last.precipTotalMm, isNull);
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
