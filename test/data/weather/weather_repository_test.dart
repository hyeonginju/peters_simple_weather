import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:peters_simple_weather/data/region/models/region.dart';
import 'package:peters_simple_weather/data/weather/local_precip_store.dart';
import 'package:peters_simple_weather/data/weather/models/forecast_result.dart';
import 'package:peters_simple_weather/data/weather/weather_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RoutedFakeAdapter implements HttpClientAdapter {
  _RoutedFakeAdapter({this.failingEndpoints = const {}});

  final Set<String> failingEndpoints;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    Map<String, dynamic> body;

    if (options.path.contains('getVilageFcst')) {
      body = _envelope(
        ok: !failingEndpoints.contains('getVilageFcst'),
        item: [
          for (final hour in ['1400', '1500', '1600'])
            ..._hourlyItems(hour),
        ],
      );
    } else if (options.path.contains('getUltraSrtNcst')) {
      body = _envelope(
        ok: !failingEndpoints.contains('getUltraSrtNcst'),
        item: [
          {'category': 'T1H', 'obsrValue': '23.5'},
          {'category': 'PTY', 'obsrValue': '0'},
          {'category': 'REH', 'obsrValue': '62'},
          {'category': 'RN1', 'obsrValue': '1.5'},
        ],
      );
    } else if (options.path.contains('getMidLandFcst')) {
      body = _envelope(
        ok: !failingEndpoints.contains('getMidLandFcst'),
        item: [
          {'regId': 'mid-land', 'rnSt4Am': 20, 'rnSt4Pm': 30},
        ],
      );
    } else if (options.path.contains('getMidTa')) {
      body = _envelope(
        ok: !failingEndpoints.contains('getMidTa'),
        item: [
          {'regId': 'mid-ta', 'taMin4': 17, 'taMax4': 26},
        ],
      );
    } else {
      throw StateError('Unexpected path: ${options.path}');
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  List<Map<String, dynamic>> _hourlyItems(String time) {
    return [
      {'category': 'TMP', 'fcstDate': '20260619', 'fcstTime': time, 'fcstValue': '24'},
      {'category': 'SKY', 'fcstDate': '20260619', 'fcstTime': time, 'fcstValue': '1'},
      {'category': 'PTY', 'fcstDate': '20260619', 'fcstTime': time, 'fcstValue': '0'},
      {'category': 'POP', 'fcstDate': '20260619', 'fcstTime': time, 'fcstValue': '10'},
      {'category': 'PCP', 'fcstDate': '20260619', 'fcstTime': time, 'fcstValue': '강수없음'},
    ];
  }

  Map<String, dynamic> _envelope({required bool ok, required dynamic item}) {
    return {
      'response': {
        'header': {'resultCode': ok ? '00' : '03', 'resultMsg': ok ? 'NORMAL_SERVICE' : 'NO_DATA'},
        'body': {'items': ok ? {'item': item} : ''},
      },
    };
  }

  @override
  void close({bool force = false}) {}
}

const _region = Region(
  id: 'seoul-yeongdeungpo',
  province: '서울특별시',
  name: '영등포구',
  nx: 58,
  ny: 126,
  midLandCode: '11B10101',
  midTaCode: '11B10101',
);

const _regionNoMidTerm = Region(
  id: 'seoul-yeongdeungpo',
  province: '서울특별시',
  name: '영등포구',
  nx: 58,
  ny: 126,
);

const _otherRegion = Region(
  id: 'busan-haeundae',
  province: '부산광역시',
  name: '해운대구',
  nx: 99,
  ny: 75,
);

WeatherRepository _buildRepository(Set<String> failingEndpoints) {
  final adapter = _RoutedFakeAdapter(failingEndpoints: failingEndpoints);
  final dio = Dio()..httpClientAdapter = adapter;
  return WeatherRepository(client: KmaApiClient(dio: dio));
}

({WeatherRepository repository, _RoutedFakeAdapter adapter}) _buildRepositoryWithAdapter(
  Set<String> failingEndpoints,
) {
  final adapter = _RoutedFakeAdapter(failingEndpoints: failingEndpoints);
  final dio = Dio()..httpClientAdapter = adapter;
  return (repository: WeatherRepository(client: KmaApiClient(dio: dio)), adapter: adapter);
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'KMA_SERVICE_KEY=test-key');
  });

  setUp(() {
    // LocalPrecipStore가 shared_preferences를 쓰므로 테스트 간 지역별 강수
    // 누적 상태가 새지 않도록 매번 초기화한다.
    SharedPreferences.setMockInitialValues({});
  });

  final now = DateTime(2026, 6, 19, 14, 30);

  test('모든 호출이 성공하면 ForecastResult.success를 반환함', () async {
    final repository = _buildRepository({});
    final result = await repository.fetch(_region, now: now);

    expect(
      result,
      isA<ForecastSuccess>()
          .having((r) => r.hourly.length, 'hourly.length', 3)
          .having((r) => r.daily, 'daily', isNotEmpty)
          .having((r) => r.snapshot.temperature, 'snapshot.temperature', 23.5)
          .having((r) => r.snapshot.humidity, 'snapshot.humidity', 62),
    );
  });

  test('오늘 처음 조회된 지역은 응답에 RN1이 있어도 무시하고 순수 예보 합산을 씀', () async {
    final repository = _buildRepository({});
    final result = await repository.fetch(_region, now: now);

    // 모든 시간대 PCP가 '강수없음'(0mm)이라 예보 합산은 0 — RN1(1.5mm)이
    // 반영됐다면 0이 아니었을 것.
    expect(
      result,
      isA<ForecastSuccess>().having((r) => r.snapshot.todayPrecipitationTotal, 'todayPrecipitationTotal', 0.0),
    );
  });

  test('이전부터 조회돼온 지역은 로컬에 쌓인 오늘자 실측치를 하이브리드로 합산함', () async {
    // firstActiveDate를 어제로 만들어 오늘은 isFirstDay=false가 되게 하고,
    // 오늘 이른 시간대에 5.0mm가 이미 관측된 것으로 시드한다.
    await LocalPrecipStore.ensureActiveAndGetState(_region.id, now.subtract(const Duration(days: 1)));
    await LocalPrecipStore.recordRn1(_region.id, now.subtract(const Duration(hours: 2)), 5.0);

    final repository = _buildRepository({});
    final result = await repository.fetch(_region, now: now);

    // 5.0(실측) + 남은 예보(전부 0mm) = 5.0
    expect(
      result,
      isA<ForecastSuccess>().having((r) => r.snapshot.todayPrecipitationTotal, 'todayPrecipitationTotal', 5.0),
    );
  });

  test('중기예보(4~10일)만 실패해도 이미 확보한 단기예보(1~3일)는 그대로 보여줌', () async {
    final repository = _buildRepository({'getMidLandFcst'});
    final result = await repository.fetch(_region, now: now);

    expect(
      result,
      isA<ForecastSuccess>()
          .having((r) => r.daily.length, 'daily.length', 1)
          .having((r) => r.snapshot.temperature, 'snapshot.temperature', 23.5),
    );
  });

  test('단기예보 자체가 실패하면 ForecastResult.failure를 반환함', () async {
    final repository = _buildRepository({'getVilageFcst'});
    final result = await repository.fetch(_region, now: now);

    expect(result, isA<ForecastFailure>());
  });

  test('초단기실황이 실패해도 단기예보 값으로 폴백해 성공 처리됨', () async {
    final repository = _buildRepository({'getUltraSrtNcst'});
    final result = await repository.fetch(_region, now: now);

    expect(
      result,
      isA<ForecastSuccess>()
          .having((r) => r.snapshot.temperature, 'snapshot.temperature', 24.0)
          .having((r) => r.snapshot.humidity, 'snapshot.humidity', isNull),
    );
  });

  test('지역에 중기예보 코드가 없으면 단기예보만으로 success 처리됨', () async {
    final repository = _buildRepository({});
    final result = await repository.fetch(_regionNoMidTerm, now: now);

    expect(result, isA<ForecastSuccess>().having((r) => r.daily.length, 'daily.length', 1));
  });

  test('10분 이내 재요청은 캐시된 결과를 반환하고 네트워크를 호출하지 않음', () async {
    final built = _buildRepositoryWithAdapter({});

    await built.repository.fetch(_region, now: now);
    final requestsAfterFirstFetch = built.adapter.requestCount;

    final second = await built.repository.fetch(_region, now: now.add(const Duration(minutes: 9)));

    expect(built.adapter.requestCount, requestsAfterFirstFetch);
    expect(second, isA<ForecastSuccess>());
  });

  test('10분이 지나면 캐시를 무시하고 다시 네트워크를 호출함', () async {
    final built = _buildRepositoryWithAdapter({});

    await built.repository.fetch(_region, now: now);
    final requestsAfterFirstFetch = built.adapter.requestCount;

    await built.repository.fetch(_region, now: now.add(const Duration(minutes: 10, seconds: 1)));

    expect(built.adapter.requestCount, greaterThan(requestsAfterFirstFetch));
  });

  test('invalidate() 호출 후에는 캐시를 무시하고 다시 네트워크를 호출함', () async {
    final built = _buildRepositoryWithAdapter({});

    await built.repository.fetch(_region, now: now);
    final requestsAfterFirstFetch = built.adapter.requestCount;

    built.repository.invalidate(_region);
    await built.repository.fetch(_region, now: now.add(const Duration(minutes: 1)));

    expect(built.adapter.requestCount, greaterThan(requestsAfterFirstFetch));
  });

  test('다른 지역은 캐시를 공유하지 않고 각각 네트워크를 호출함', () async {
    final built = _buildRepositoryWithAdapter({});

    await built.repository.fetch(_region, now: now);
    final requestsAfterFirstFetch = built.adapter.requestCount;

    await built.repository.fetch(_otherRegion, now: now);

    expect(built.adapter.requestCount, greaterThan(requestsAfterFirstFetch));
  });
}
