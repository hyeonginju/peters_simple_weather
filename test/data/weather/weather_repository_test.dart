import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:peters_simple_weather/data/region/models/region.dart';
import 'package:peters_simple_weather/data/weather/models/forecast_result.dart';
import 'package:peters_simple_weather/data/weather/weather_repository.dart';

class _RoutedFakeAdapter implements HttpClientAdapter {
  _RoutedFakeAdapter({this.failingEndpoints = const {}});

  final Set<String> failingEndpoints;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

WeatherRepository _buildRepository(Set<String> failingEndpoints) {
  final dio = Dio()..httpClientAdapter = _RoutedFakeAdapter(failingEndpoints: failingEndpoints);
  return WeatherRepository(client: KmaApiClient(dio: dio));
}

void main() {
  setUpAll(() {
    dotenv.loadFromString(envString: 'KMA_SERVICE_KEY=test-key');
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
          .having((r) => r.snapshot.temperature, 'snapshot.temperature', 23.5),
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
      isA<ForecastSuccess>().having((r) => r.snapshot.temperature, 'snapshot.temperature', 24.0),
    );
  });

  test('지역에 중기예보 코드가 없으면 단기예보만으로 success 처리됨', () async {
    final repository = _buildRepository({});
    final result = await repository.fetch(_regionNoMidTerm, now: now);

    expect(result, isA<ForecastSuccess>().having((r) => r.daily.length, 'daily.length', 1));
  });
}
