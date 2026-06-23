import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:peters_simple_weather/app.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:peters_simple_weather/data/weather/weather_repository.dart';
import 'package:peters_simple_weather/features/home/providers/weather_providers.dart';

String _today() {
  final n = DateTime.now();
  return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
}

class _FakeAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final today = _today();
    final dynamic item = options.path.contains('vilage-fcst')
        ? [
            for (final hour in ['0900', '1200', '1500', '1800'])
              ...[
                {'category': 'TMP', 'fcstDate': today, 'fcstTime': hour, 'fcstValue': '24'},
                {'category': 'SKY', 'fcstDate': today, 'fcstTime': hour, 'fcstValue': '1'},
                {'category': 'PTY', 'fcstDate': today, 'fcstTime': hour, 'fcstValue': '0'},
                {'category': 'POP', 'fcstDate': today, 'fcstTime': hour, 'fcstValue': '10'},
                {'category': 'PCP', 'fcstDate': today, 'fcstTime': hour, 'fcstValue': '강수없음'},
              ],
          ]
        : options.path.contains('ultra-srt-ncst')
            ? [
                {'category': 'T1H', 'obsrValue': '24'},
                {'category': 'PTY', 'obsrValue': '0'},
              ]
            : options.path.contains('mid-land-fcst')
                ? [
                    {'regId': 'mid-land', 'rnSt4Am': 10, 'rnSt4Pm': 10},
                  ]
                : [
                    {'regId': 'mid-ta', 'taMin4': 18, 'taMax4': 27},
                  ];

    final body = {
      'response': {
        'header': {'resultCode': '00', 'resultMsg': 'NORMAL_SERVICE'},
        'body': {'items': {'item': item}},
      },
    };
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('지역 데이터가 있으면 현재 날씨·옷차림·예보 섹션이 표시됨', (tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_region_ids': ['서울특별시/영등포구'],
    });
    final dio = Dio()..httpClientAdapter = _FakeAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(WeatherRepository(client: KmaApiClient(dio: dio))),
        ],
        child: CleanWeatherApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('영등포구'), findsOneWidget);
    expect(find.text('맑음'), findsOneWidget);
    // 24° → 23~27 밴드 → "가볍게 입기 좋아요" 헤드라인
    expect(find.text('가볍게 입기 좋아요'), findsOneWidget);
    expect(find.text('시간별 예보'), findsOneWidget);
    expect(find.text('주간 예보'), findsOneWidget);
    expect(find.text('지금'), findsOneWidget);
  });
}
