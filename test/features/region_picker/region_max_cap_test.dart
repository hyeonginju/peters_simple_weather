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

/// Always returns a minimal successful envelope for whichever KMA endpoint
/// is requested, so the home screen's weather fetch doesn't hit the network
/// during this widget test.
class _FakeSuccessAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final dynamic item = options.path.contains('vilage-fcst')
        ? [
            {'category': 'TMP', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '24'},
            {'category': 'SKY', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '1'},
            {'category': 'PTY', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '0'},
            {'category': 'POP', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '10'},
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
  testWidgets('지역은 최대 10개까지만 추가할 수 있다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_region_ids': [
        '서울특별시/영등포구',
        '서울특별시/강남구',
        '서울특별시/노원구',
        '서울특별시/구로구',
        '서울특별시/마포구',
        '서울특별시/강서구',
        '서울특별시/관악구',
        '서울특별시/광진구',
        '서울특별시/금천구',
        '서울특별시/동작구',
      ],
    });

    final dio = Dio()..httpClientAdapter = _FakeSuccessAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(WeatherRepository(client: KmaApiClient(dio: dio))),
        ],
        child: CleanWeatherApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('내 지역 관리'));
    await tester.pumpAndSettle();

    // 10개가 꽉 차면 추가 카드가 보이지 않아야 함
    expect(find.text('지역 추가'), findsNothing);
  });
}
