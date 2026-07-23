import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/alert/alert_disk_cache.dart';
import 'package:peters_simple_weather/data/alert/alert_repository.dart';
import 'package:peters_simple_weather/data/alert/models/weather_alert.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:peters_simple_weather/features/alerts/providers/alert_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 네트워크에서 온 "새" 통보문임을 구분할 수 있게 t1을 FRESH로 응답한다
/// (디스크 캐시의 stale 데이터는 STALE). [delay]로 응답을 늦춰 "갱신 진행 중"
/// 상태가 열려 있는 시간을 만들 수 있다(콜드스타트 시뮬레이션).
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({this.delay = Duration.zero});

  final Duration delay;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return ResponseBody.fromString(
      jsonEncode({
        'response': {
          'header': {'resultCode': '00', 'resultMsg': 'NORMAL_SERVICE'},
          'body': {
            'items': {
              'item': [
                {
                  'stnId': '133',
                  't1': 'FRESH',
                  't6': 'o 폭염주의보 : 대전',
                  't7': 'o 없음',
                  'tmFc': 202607231000,
                },
              ],
            },
          },
        },
      }),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

const _stnId = '133';

const _staleStatus = WeatherAlertStatus(
  regionLabel: '대전·세종·충남',
  announcedAt: null,
  latestTitle: 'STALE',
  currentAlerts: 'o 호우주의보 : 대전(동구, 중구)',
  preliminaryAlerts: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  ProviderContainer buildContainer(_FakeAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    return ProviderContainer(overrides: [
      alertRepositoryProvider.overrideWithValue(AlertRepository(client: KmaApiClient(dio: dio))),
    ]);
  }

  Future<void> seedStaleCache() =>
      AlertDiskCache().save(_stnId, _staleStatus, DateTime.now().subtract(const Duration(hours: 1)));

  test('TTL 지난 디스크 캐시가 있으면 stale을 즉시 반환하고 백그라운드로 갱신함', () async {
    await seedStaleCache();

    final adapter = _FakeAdapter();
    final container = buildContainer(adapter);
    addTearDown(container.dispose);
    final sub = container.listen(alertStatusProvider(_stnId), (_, _) {});
    addTearDown(sub.close);

    // 첫 값 = 디스크의 stale 통보문이 즉시 온다(네트워크 대기 없음).
    final first = await container.read(alertStatusProvider(_stnId).future);
    expect(first.latestTitle, 'STALE');

    // 백그라운드 revalidate가 끝나면 상태가 새 통보문으로 교체된다.
    await _pumpUntil(() => container.read(alertStatusProvider(_stnId)).value?.latestTitle == 'FRESH');
    expect(adapter.requestCount, greaterThan(0));
  });

  test('갱신 시작 뒤에 구독해도(화면: 라벨이 늦게 붙음) 진행 중 상태가 보임', () async {
    // 홈 인디케이터가 실기기에서 안 뜨던 회귀 시나리오와 동일: 화면(리스너)은
    // stale이 그려진 다음에야 alertRefreshing을 구독한다. autoDispose였다면
    // 리스너 없는 set(true)가 인스턴스째 폐기돼 늦은 구독자는 false만 본다.
    await seedStaleCache();

    final container = buildContainer(_FakeAdapter(delay: const Duration(milliseconds: 300)));
    addTearDown(container.dispose);
    final sub = container.listen(alertStatusProvider(_stnId), (_, _) {});
    addTearDown(sub.close);

    await container.read(alertStatusProvider(_stnId).future);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(container.read(alertRefreshingProvider(_stnId)), isTrue,
        reason: '갱신(300ms 지연 응답)이 아직 진행 중');

    await _pumpUntil(() => container.read(alertRefreshingProvider(_stnId)) == false);
  });

  test('갱신이 실패하면 stale 화면을 그대로 유지함', () async {
    await seedStaleCache();

    // 모든 요청이 실패하는 어댑터 — revalidate가 예외로 끝나는 경우.
    final dio = Dio()..httpClientAdapter = _ThrowingAdapter();
    final container = ProviderContainer(overrides: [
      alertRepositoryProvider.overrideWithValue(AlertRepository(client: KmaApiClient(dio: dio))),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(alertStatusProvider(_stnId), (_, _) {});
    addTearDown(sub.close);

    final first = await container.read(alertStatusProvider(_stnId).future);
    expect(first.latestTitle, 'STALE');

    await _pumpUntil(() => container.read(alertRefreshingProvider(_stnId)) == false);

    final after = container.read(alertStatusProvider(_stnId));
    expect(after.hasError, isFalse, reason: 'stale 유지 — 에러 화면으로 덮지 않음');
    expect(after.value?.latestTitle, 'STALE');
  });

  test('디스크 캐시가 없으면 평소처럼 네트워크를 기다림', () async {
    final adapter = _FakeAdapter();
    final container = buildContainer(adapter);
    addTearDown(container.dispose);
    final sub = container.listen(alertStatusProvider(_stnId), (_, _) {});
    addTearDown(sub.close);

    final first = await container.read(alertStatusProvider(_stnId).future);

    expect(first.latestTitle, 'FRESH');
    expect(adapter.requestCount, greaterThan(0));
  });
}

class _ThrowingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException.connectionError(requestOptions: options, reason: 'down');
  }

  @override
  void close({bool force = false}) {}
}

/// revalidate는 microtask+비동기 IO라 완료 시점을 폴링으로 기다린다.
Future<void> _pumpUntil(bool Function() condition) async {
  for (var i = 0; i < 100; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('조건이 2초 안에 충족되지 않음');
}
