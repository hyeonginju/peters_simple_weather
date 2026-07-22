import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:peters_simple_weather/app.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:peters_simple_weather/data/weather/forecast_disk_cache.dart';
import 'package:peters_simple_weather/data/weather/models/daily_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/forecast_result.dart';
import 'package:peters_simple_weather/data/weather/models/hourly_forecast.dart';
import 'package:peters_simple_weather/data/weather/models/kma_forecast_item.dart';
import 'package:peters_simple_weather/data/weather/models/weather_snapshot.dart';
import 'package:peters_simple_weather/data/weather/weather_repository.dart';
import 'package:peters_simple_weather/features/home/providers/weather_providers.dart';

/// 백엔드 콜드스타트처럼 모든 응답을 [delay]만큼 늦춘다 — 그동안 화면은
/// 디스크 캐시를 그리고 좌상단에 '업데이트 중'이 떠 있어야 한다.
class _SlowAdapter implements HttpClientAdapter {
  static const delay = Duration(seconds: 5);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await Future<void>.delayed(delay);

    if (options.path.contains('precip-today')) {
      return _json({'accumulatedRn': 0.0, 'lastSlot': null, 'isFirstDay': true});
    }
    if (options.path.contains('air-quality')) {
      return _json({'pm10': 30, 'pm10Grade': 1, 'pm25': 15, 'pm25Grade': 1});
    }

    final item = options.path.contains('vilage-fcst')
        ? [
            {'category': 'TMP', 'fcstDate': _today(), 'fcstTime': '1400', 'fcstValue': '23.5'},
            {'category': 'SKY', 'fcstDate': _today(), 'fcstTime': '1400', 'fcstValue': '1'},
            {'category': 'PTY', 'fcstDate': _today(), 'fcstTime': '1400', 'fcstValue': '0'},
            {'category': 'POP', 'fcstDate': _today(), 'fcstTime': '1400', 'fcstValue': '10'},
            {'category': 'PCP', 'fcstDate': _today(), 'fcstTime': '1400', 'fcstValue': '강수없음'},
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

  String _today() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }

  ResponseBody _json(Map<String, dynamic> body) => ResponseBody.fromString(
        jsonEncode(body),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );

  @override
  void close({bool force = false}) {}
}

const _regionId = '서울특별시/영등포구';

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
    DailyForecast(date: DateTime.now(), minTemp: 20, maxTemp: 30, popPercent: 0),
  ],
);

void main() {
  testWidgets('디스크 캐시 표시 중 백그라운드 갱신이 돌면 좌상단에 "업데이트 중"이 보임', (tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_region_ids': [_regionId],
    });
    // TTL(10분)이 지난 디스크 캐시 — 즉시 그려지고 백그라운드 갱신이 돈다.
    await ForecastDiskCache()
        .save(_regionId, _staleSuccess, DateTime.now().subtract(const Duration(hours: 1)));

    final dio = Dio()..httpClientAdapter = _SlowAdapter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(WeatherRepository(client: KmaApiClient(dio: dio))),
        ],
        child: CleanWeatherApp(),
      ),
    );

    // regions.json 자산 로딩은 실 IO라 가짜 시계 점프로는 안 기다려진다 —
    // 짧은 펌프를 반복해 이벤트 루프에 실 IO가 낄 틈을 준다. 가짜 시계는
    // 총 3초 경과: 어댑터 지연(요청당 5초)보다 짧아 갱신은 아직 진행 중.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('99°'), findsWidgets, reason: '디스크 캐시(99.0°)가 즉시 그려져야 함');
    expect(find.text('업데이트 중'), findsOneWidget, reason: '백그라운드 갱신 중 인디케이터가 보여야 함');

    // 순차 요청 6개 × 5초 = ~30초 뒤 갱신 완료: 인디케이터가 사라지고
    // 새 데이터(23.5→24° 반올림)로 교체됨.
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('업데이트 중'), findsNothing);
    expect(find.text('24°'), findsWidgets, reason: '갱신된 기온(23.5→24°)으로 교체돼야 함');
  });
}
