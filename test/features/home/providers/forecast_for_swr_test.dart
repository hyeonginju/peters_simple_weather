import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:peters_simple_weather/data/region/models/region.dart';
import 'package:peters_simple_weather/data/weather/forecast_disk_cache.dart';
import 'package:peters_simple_weather/data/weather/models/daily_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/forecast_result.dart';
import 'package:peters_simple_weather/data/weather/models/hourly_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';
import 'package:peters_simple_weather/data/weather/models/weather_snapshot.dart';
import 'package:peters_simple_weather/data/weather/weather_repository.dart';
import 'package:peters_simple_weather/features/home/providers/weather_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 네트워크에서 온 "새" 데이터임을 구분할 수 있게 기온을 23.5로 응답한다
/// (디스크 캐시의 stale 데이터는 99.0).
class _FakeAdapter implements HttpClientAdapter {
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;

    if (options.path.contains('precip-today')) {
      return _json({'accumulatedRn': 0.0, 'lastSlot': null, 'isFirstDay': true});
    }
    if (options.path.contains('air-quality')) {
      return _json({'pm10': 30, 'pm10Grade': 1, 'pm25': 15, 'pm25Grade': 1});
    }

    final item = options.path.contains('vilage-fcst')
        ? [
            {'category': 'TMP', 'fcstDate': '20260722', 'fcstTime': '1400', 'fcstValue': '23.5'},
            {'category': 'SKY', 'fcstDate': '20260722', 'fcstTime': '1400', 'fcstValue': '1'},
            {'category': 'PTY', 'fcstDate': '20260722', 'fcstTime': '1400', 'fcstValue': '0'},
            {'category': 'POP', 'fcstDate': '20260722', 'fcstTime': '1400', 'fcstValue': '10'},
            {'category': 'PCP', 'fcstDate': '20260722', 'fcstTime': '1400', 'fcstValue': '강수없음'},
          ]
        : [
            {'category': 'T1H', 'obsrValue': '23.5'},
            {'category': 'PTY', 'obsrValue': '0'},
          ];
    return _json({
      'response': {
        'header': {'resultCode': '00', 'resultMsg': 'NORMAL_SERVICE'},
        'body': {'items': {'item': item}},
      },
    });
  }

  ResponseBody _json(Map<String, dynamic> body) => ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );

  @override
  void close({bool force = false}) {}
}

const _region = Region(id: '서울특별시/영등포구', province: '서울특별시', name: '영등포구', nx: 58, ny: 126);

final _staleSuccess = ForecastSuccess(
  snapshot: const WeatherSnapshot(
    temperature: 99.0,
    sky: SkyCondition.clear,
    precipitationType: PrecipitationType.none,
    precipitationAmount: 0.0,
    precipitationProbability: 0,
    todayPrecipitationTotal: 0.0,
  ),
  hourly: [
    HourlyForecast(
      time: DateTime.now(),
      temperature: 99.0,
      sky: SkyCondition.clear,
      precipitationType: PrecipitationType.none,
      precipitationAmount: 0.0,
      precipitationProbability: 0,
    ),
  ],
  daily: [
    DailyForecast(date: DateTime.now(), minTemp: 90, maxTemp: 99, popPercent: 0),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer buildContainer(_FakeAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    return ProviderContainer(overrides: [
      weatherRepositoryProvider.overrideWithValue(WeatherRepository(client: KmaApiClient(dio: dio))),
    ]);
  }

  test('TTL 지난 디스크 캐시가 있으면 stale을 즉시 반환하고 백그라운드로 갱신함', () async {
    // 1시간 전에 저장된(=TTL 만료) 디스크 캐시.
    await ForecastDiskCache()
        .save(_region.id, _staleSuccess, DateTime.now().subtract(const Duration(hours: 1)));

    final adapter = _FakeAdapter();
    final container = buildContainer(adapter);
    addTearDown(container.dispose);
    final sub = container.listen(forecastForProvider(_region), (_, __) {});
    addTearDown(sub.close);

    // 첫 값 = 디스크의 stale 데이터가 즉시 온다(네트워크 대기 없음).
    final first = await container.read(forecastForProvider(_region).future);
    expect(first, isA<ForecastSuccess>().having((r) => r.snapshot.temperature, 'temperature', 99.0));

    // 백그라운드 revalidate가 끝나면 상태가 새 데이터로 교체된다.
    await _pumpUntil(() {
      final value = container.read(forecastForProvider(_region)).value;
      return value is ForecastSuccess && value.snapshot.temperature == 23.5;
    });
    expect(adapter.requestCount, greaterThan(0));
  });

  test('갱신 중에는 regionRefreshing이 true였다가 끝나면 false로 돌아옴', () async {
    await ForecastDiskCache()
        .save(_region.id, _staleSuccess, DateTime.now().subtract(const Duration(hours: 1)));

    final container = buildContainer(_FakeAdapter());
    addTearDown(container.dispose);
    final sub = container.listen(forecastForProvider(_region), (_, __) {});
    addTearDown(sub.close);
    final seen = <bool>[];
    final refreshingSub =
        container.listen(regionRefreshingProvider(_region), (_, v) => seen.add(v));
    addTearDown(refreshingSub.close);

    await container.read(forecastForProvider(_region).future);
    await _pumpUntil(() => seen.contains(true) && seen.last == false);

    expect(seen.first, isTrue, reason: '갱신 시작 시 true');
    expect(seen.last, isFalse, reason: '갱신 종료 시 false');
  });

  test('디스크 캐시가 없으면 평소처럼 네트워크를 기다림', () async {
    final adapter = _FakeAdapter();
    final container = buildContainer(adapter);
    addTearDown(container.dispose);
    final sub = container.listen(forecastForProvider(_region), (_, __) {});
    addTearDown(sub.close);

    final first = await container.read(forecastForProvider(_region).future);

    expect(first, isA<ForecastSuccess>().having((r) => r.snapshot.temperature, 'temperature', 23.5));
    expect(adapter.requestCount, greaterThan(0));
  });
}

/// revalidate는 microtask+비동기 IO라 완료 시점을 폴링으로 기다린다.
Future<void> _pumpUntil(bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('조건이 2초 안에 충족되지 않음');
}
