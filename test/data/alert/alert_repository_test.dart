import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/alert/alert_repository.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.item);

  /// 통보문 1건의 필드 맵. null이면 빈 응답(통보문 없음)을 흉내낸다.
  final Map<String, dynamic>? item;

  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requestCount++;
    final body = {
      'response': {
        'header': {'resultCode': '00', 'resultMsg': 'NORMAL_SERVICE'},
        'body': {
          'items': item == null ? '' : {'item': [item]},
        },
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

AlertRepository _repo(Map<String, dynamic>? item, {_FakeAdapter? adapter}) {
  final dio = Dio()..httpClientAdapter = (adapter ?? _FakeAdapter(item));
  return AlertRepository(client: KmaApiClient(dio: dio));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final now = DateTime(2026, 6, 22, 15, 0);

  test('발효 중인 특보가 있으면 hasActiveAlert=true와 본문을 채운다', () async {
    final status = await _repo({
      'stnId': '133',
      't1': '호우주의보 발표',
      't6': 'o 호우주의보 : 대전(동구, 중구)',
      't7': 'o 없음',
      'tmFc': 202606220530,
    }).fetchByStnId('133', now: now);

    expect(status.hasActiveAlert, isTrue);
    expect(status.currentAlerts, contains('호우주의보'));
    expect(status.preliminaryAlerts, isEmpty); // t7 "o 없음" → 빈 값
    expect(status.regionLabel, '대전·세종·충남');
    expect(status.announcedAt, DateTime(2026, 6, 22, 5, 30));
  });

  test('t6가 "o 없음"이면(중간 공백 포함) 발효 특보 없음으로 처리한다', () async {
    final status = await _repo({
      'stnId': '133',
      't1': '호우주의보 해제',
      't6': 'o 없 음',
      't7': 'o 없음',
      'tmFc': 202606200700,
    }).fetchByStnId('133', now: now);

    expect(status.hasActiveAlert, isFalse);
    expect(status.currentAlerts, isEmpty);
    expect(status.latestTitle, '호우주의보 해제');
  });

  test('예비특보가 있으면 preliminaryAlerts를 채운다', () async {
    final status = await _repo({
      'stnId': '108',
      't1': '강풍 예비특보',
      't6': 'o 없음',
      't7': 'o 06월 23일 새벽 : 제주도',
      'tmFc': 202606221200,
    }).fetchByStnId('108', now: now);

    expect(status.hasActiveAlert, isFalse);
    expect(status.preliminaryAlerts, contains('제주도'));
    expect(status.regionLabel, '전국');
  });

  test('통보문이 없으면 빈 발효 현황을 반환한다', () async {
    final status = await _repo(null).fetchByStnId('131', now: now);

    expect(status.hasActiveAlert, isFalse);
    expect(status.currentAlerts, isEmpty);
    expect(status.announcedAt, isNull);
    expect(status.regionLabel, '충청북도');
  });

  group('캐시(SWR)', () {
    final item = {
      'stnId': '133',
      't1': '호우주의보 발표',
      't6': 'o 호우주의보 : 대전(동구, 중구)',
      't7': 'o 없음',
      'tmFc': 202606220530,
    };

    test('TTL(5분) 안의 재조회는 네트워크 없이 메모리 캐시를 반환한다', () async {
      final adapter = _FakeAdapter(item);
      final repo = _repo(null, adapter: adapter);

      await repo.fetchByStnId('133', now: now);
      final again = await repo.fetchByStnId('133', now: now.add(const Duration(minutes: 4)));

      expect(adapter.requestCount, 1);
      expect(again.hasActiveAlert, isTrue);
      expect(repo.isFresh('133', now: now.add(const Duration(minutes: 4))), isTrue);
    });

    test('TTL이 지나면 다시 네트워크를 탄다', () async {
      final adapter = _FakeAdapter(item);
      final repo = _repo(null, adapter: adapter);

      await repo.fetchByStnId('133', now: now);
      expect(repo.isFresh('133', now: now.add(const Duration(minutes: 6))), isFalse);

      await repo.fetchByStnId('133', now: now.add(const Duration(minutes: 6)));

      expect(adapter.requestCount, 2);
    });

    test('새 리포지토리 인스턴스(앱 재시작)가 디스크에서 직전 현황을 복원한다', () async {
      // 첫 인스턴스가 fetch로 디스크에 저장.
      await _repo(item).fetchByStnId('133', now: now);

      // 새 인스턴스: 네트워크를 타지 않고 staleResult로 복원돼야 한다.
      final adapter = _FakeAdapter(null);
      final restored = await _repo(null, adapter: adapter).staleResult('133', now: now.add(const Duration(hours: 1)));

      expect(adapter.requestCount, 0);
      expect(restored, isNotNull);
      expect(restored!.currentAlerts, contains('호우주의보'));
    });

    test('디스크에도 없으면 staleResult는 null', () async {
      expect(await _repo(null).staleResult('133', now: now), isNull);
    });

    test('invalidate 후에는 TTL 안이어도 네트워크를 탄다', () async {
      final adapter = _FakeAdapter(item);
      final repo = _repo(null, adapter: adapter);

      await repo.fetchByStnId('133', now: now);
      repo.invalidate('133');
      await repo.fetchByStnId('133', now: now.add(const Duration(minutes: 1)));

      expect(adapter.requestCount, 2);
    });
  });
}
