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
            {'category': 'TMP', 'fcstDate': today, 'fcstTime': '1400', 'fcstValue': '24'},
            {'category': 'SKY', 'fcstDate': today, 'fcstTime': '1400', 'fcstValue': '1'},
            {'category': 'PTY', 'fcstDate': today, 'fcstTime': '1400', 'fcstValue': '0'},
            {'category': 'POP', 'fcstDate': today, 'fcstTime': '1400', 'fcstValue': '10'},
          ]
        : options.path.contains('ultra-srt-ncst')
            ? [
                {'category': 'T1H', 'obsrValue': '24'},
                {'category': 'PTY', 'obsrValue': '0'},
              ]
            : options.path.contains('mid-land-fcst')
                ? [
                    {'regId': 'mid-land', 'rnSt4Am': 70, 'rnSt4Pm': 50, 'wf4Am': '비'},
                  ]
                : [
                    {'regId': 'mid-ta', 'taMin4': 18, 'taMax4': 26},
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
  testWidgets('"주간 예보" 섹션 제목을 탭하면 기온 추세 차트 상세로 이동함', (tester) async {
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

    // 메인의 주간 예보 섹션 제목 탭 → 상세 이동
    await tester.ensureVisible(find.text('주간 예보'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('주간 예보'));
    await tester.pumpAndSettle();

    expect(find.text('기온 추세'), findsOneWidget);
    expect(find.text('최고'), findsOneWidget);
    expect(find.text('최저'), findsOneWidget);
  });
}
