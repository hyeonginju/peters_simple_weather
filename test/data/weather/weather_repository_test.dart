import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:peters_simple_weather/data/region/models/region.dart';
import 'package:peters_simple_weather/data/weather/models/forecast_result.dart';
import 'package:peters_simple_weather/data/weather/weather_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RoutedFakeAdapter implements HttpClientAdapter {
  _RoutedFakeAdapter({
    this.failingEndpoints = const {},
    this.precipAccumulatedRn = 0.0,
    this.precipIsFirstDay = false,
  });

  final Set<String> failingEndpoints;
  final double precipAccumulatedRn;
  final bool precipIsFirstDay;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;

    if (options.path.contains('precip-today')) {
      return ResponseBody.fromString(
        jsonEncode({'accumulatedRn': precipAccumulatedRn, 'lastSlot': null, 'isFirstDay': precipIsFirstDay}),
        200,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );
    }

    Map<String, dynamic> body;

    if (options.path.contains('vilage-fcst')) {
      body = _envelope(
        ok: !failingEndpoints.contains('getVilageFcst'),
        item: [
          for (final hour in ['1400', '1500', '1600'])
            ..._hourlyItems(hour),
        ],
      );
    } else if (options.path.contains('ultra-srt-ncst')) {
      body = _envelope(
        ok: !failingEndpoints.contains('getUltraSrtNcst'),
        item: [
          {'category': 'T1H', 'obsrValue': '23.5'},
          {'category': 'PTY', 'obsrValue': '0'},
          {'category': 'REH', 'obsrValue': '62'},
        ],
      );
    } else if (options.path.contains('mid-land-fcst')) {
      body = _envelope(
        ok: !failingEndpoints.contains('getMidLandFcst'),
        item: [
          {'regId': 'mid-land', 'rnSt4Am': 20, 'rnSt4Pm': 30},
        ],
      );
    } else if (options.path.contains('mid-ta')) {
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

WeatherRepository _buildRepository(
  Set<String> failingEndpoints, {
  double precipAccumulatedRn = 0.0,
  bool precipIsFirstDay = false,
}) {
  final adapter = _RoutedFakeAdapter(
    failingEndpoints: failingEndpoints,
    precipAccumulatedRn: precipAccumulatedRn,
    precipIsFirstDay: precipIsFirstDay,
  );
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

  test('처음 조회되는 지역(isFirstDay)은 실측 대신 하루 전체 예보값을 합산함', () async {
    final repository = _buildRepository({}, precipAccumulatedRn: 3.0, precipIsFirstDay: true);
    final result = await repository.fetch(_region, now: now);

    // 9시(1.0mm, 이미 지난 시간대)까지 포함해 강수 예보 없는 나머지 시간대는 0 —
    // 실측(3.0mm)은 무시되고 순수 예보 합산만 쓰임.
    expect(
      result,
      isA<ForecastSuccess>().having((r) => r.snapshot.todayPrecipitationTotal, 'todayPrecipitationTotal', 0.0),
    );
  });

  test('이미 조회 이력이 있는 지역은 실측+남은 예보를 하이브리드로 합산함', () async {
    final repository = _buildRepository({}, precipAccumulatedRn: 3.0, precipIsFirstDay: false);
    final result = await repository.fetch(_region, now: now);

    expect(
      result,
      isA<ForecastSuccess>().having((r) => r.snapshot.todayPrecipitationTotal, 'todayPrecipitationTotal', 3.0),
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

  group('디스크 캐시(SWR)', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('fetch 성공 결과가 디스크에 남아 새 프로세스(새 리포지토리)에서 staleResult로 복원됨', () async {
      await _buildRepository({}).fetch(_region, now: now);

      // 새 리포지토리 = 앱 프로세스 재시작(메모리 캐시 없음) 시뮬레이션.
      final restarted = _buildRepositoryWithAdapter({});
      final stale = await restarted.repository.staleResult(_region, now: now.add(const Duration(hours: 2)));

      expect(stale, isA<ForecastSuccess>().having((r) => r.snapshot.temperature, 'temperature', 23.5));
      // 복원은 디스크에서만 — 네트워크 호출 없음.
      expect(restarted.adapter.requestCount, 0);
      // "마지막 업데이트" 라벨용 fetch 시각도 원래 시각으로 복원됨.
      expect(restarted.repository.fetchedAtFor(_region), now);
    });

    test('복원된 캐시는 TTL이 지난 상태라 isFresh가 false — 백그라운드 갱신 대상', () async {
      await _buildRepository({}).fetch(_region, now: now);

      final restarted = _buildRepository({});
      final later = now.add(const Duration(hours: 2));
      await restarted.staleResult(_region, now: later);

      expect(restarted.isFresh(_region, now: later), isFalse);
    });

    test('fetch 직후에는 isFresh가 true', () async {
      final repository = _buildRepository({});
      await repository.fetch(_region, now: now);

      expect(repository.isFresh(_region, now: now.add(const Duration(minutes: 5))), isTrue);
    });

    test('디스크에 아무것도 없으면 staleResult는 null', () async {
      expect(await _buildRepository({}).staleResult(_region, now: now), isNull);
    });

    test('실패 결과는 디스크에 저장되지 않음', () async {
      await _buildRepository({'getVilageFcst'}).fetch(_region, now: now);

      expect(await _buildRepository({}).staleResult(_region, now: now), isNull);
    });
  });
}
