import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:peters_simple_weather/app.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:peters_simple_weather/data/weather/weather_repository.dart';
import 'package:peters_simple_weather/features/home/providers/weather_providers.dart';

/// Simulates total KMA downtime: every request fails the transport itself.
class _AlwaysFailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(requestOptions: options, reason: 'network down');
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  testWidgets('기상청 API가 모두 실패하면 전체 장애 에러 UI가 표시됨 (다크모드 포함)', (tester) async {
    SharedPreferences.setMockInitialValues({
      'saved_region_ids': ['서울특별시/영등포구'],
    });

    final dio = Dio()..httpClientAdapter = _AlwaysFailingAdapter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          weatherRepositoryProvider.overrideWithValue(WeatherRepository(client: KmaApiClient(dio: dio))),
        ],
        child: MediaQuery(
          data: const MediaQueryData(platformBrightness: Brightness.dark),
          child: CleanWeatherApp(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('기상청 서버에서 데이터를\n불러오지 못했습니다.'), findsOneWidget);
    expect(find.text('잠시 후 다시 시도해 주세요.'), findsOneWidget);

    final retryButton = find.text('다시 시도');
    expect(retryButton, findsOneWidget);

    // 다시 시도를 눌러도 크래시 없이 같은 에러 화면으로 돌아옴(여전히 실패 응답).
    await tester.tap(retryButton);
    await tester.pumpAndSettle();
    expect(find.text('기상청 서버에서 데이터를\n불러오지 못했습니다.'), findsOneWidget);
  });
}
