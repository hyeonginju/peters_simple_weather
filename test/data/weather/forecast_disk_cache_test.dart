import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/forecast_disk_cache.dart';
import 'package:peters_simple_weather/data/weather/models/air_quality.dart';
import 'package:peters_simple_weather/data/weather/models/daily_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/forecast_result.dart';
import 'package:peters_simple_weather/data/weather/models/hourly_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';
import 'package:peters_simple_weather/data/weather/models/weather_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _snapshot = WeatherSnapshot(
  temperature: 23.5,
  sky: SkyCondition.partlyCloudy,
  precipitationType: PrecipitationType.rain,
  precipitationAmount: 1.5,
  precipitationProbability: 60,
  todayPrecipitationTotal: 12.5,
  humidity: 78,
  airQuality: AirQuality(pm10: 30, pm10Grade: AirGrade.good, pm25: 15, pm25Grade: AirGrade.moderate),
);

final _success = ForecastSuccess(
  snapshot: _snapshot,
  hourly: [
    HourlyForecast(
      time: DateTime(2026, 7, 22, 22),
      temperature: 24.0,
      sky: SkyCondition.cloudy,
      precipitationType: PrecipitationType.none,
      precipitationAmount: 0.0,
      precipitationProbability: 30,
    ),
  ],
  daily: [
    DailyForecast(
      date: DateTime(2026, 7, 26),
      minTemp: 24,
      maxTemp: 28,
      popPercent: 60,
      amPop: 60,
      pmPop: 60,
      precipTotalMm: null,
      sky: SkyCondition.cloudy,
      precipitationType: PrecipitationType.rain,
    ),
    // nullable 필드가 전부 비어 있는 날(중기예보 유래 없음)도 라운드트립돼야 함.
    DailyForecast(date: DateTime(2026, 7, 27), minTemp: 20, maxTemp: 30, popPercent: 0),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fetchedAt = DateTime(2026, 7, 22, 21, 30);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save 후 load하면 모든 필드가 라운드트립됨', () async {
    final cache = ForecastDiskCache();
    await cache.save('seoul', _success, fetchedAt);

    final loaded = await cache.load('seoul', fetchedAt.add(const Duration(hours: 1)));

    expect(loaded, isNotNull);
    expect(loaded!.fetchedAt, fetchedAt);
    final s = loaded.result.snapshot;
    expect(s.temperature, 23.5);
    expect(s.sky, SkyCondition.partlyCloudy);
    expect(s.precipitationType, PrecipitationType.rain);
    expect(s.todayPrecipitationTotal, 12.5);
    expect(s.humidity, 78);
    expect(s.airQuality?.pm10Grade, AirGrade.good);
    expect(s.airQuality?.pm25Grade, AirGrade.moderate);
    expect(loaded.result.hourly.single.time, DateTime(2026, 7, 22, 22));
    expect(loaded.result.hourly.single.precipitationProbability, 30);
    final day = loaded.result.daily.first;
    expect(day.date, DateTime(2026, 7, 26));
    expect(day.amPop, 60);
    expect(day.precipTotalMm, isNull);
    expect(day.precipitationType, PrecipitationType.rain);
    final bareDay = loaded.result.daily.last;
    expect(bareDay.sky, isNull);
    expect(bareDay.amPop, isNull);
  });

  test('maxAge(24시간)를 넘은 캐시는 없는 것으로 취급함', () async {
    final cache = ForecastDiskCache();
    await cache.save('seoul', _success, fetchedAt);

    final loaded = await cache.load('seoul', fetchedAt.add(const Duration(hours: 25)));

    expect(loaded, isNull);
  });

  test('저장된 것이 없으면 null', () async {
    expect(await ForecastDiskCache().load('seoul', fetchedAt), isNull);
  });

  test('깨진 JSON(구버전 캐시 등)은 버리고 null을 반환함', () async {
    SharedPreferences.setMockInitialValues({'forecast_cache_seoul': '{corrupt'});
    expect(await ForecastDiskCache().load('seoul', fetchedAt), isNull);
  });

  test('지역별로 따로 저장됨', () async {
    final cache = ForecastDiskCache();
    await cache.save('seoul', _success, fetchedAt);

    expect(await cache.load('busan', fetchedAt), isNull);
  });
}
