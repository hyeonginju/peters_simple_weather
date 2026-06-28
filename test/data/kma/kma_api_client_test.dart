import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/kma/kma_api_client.dart';
import 'package:peters_simple_weather/data/kma/kma_api_exception.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.jsonBody);

  final Map<String, dynamic> jsonBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(jsonBody),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 첫 호출은 DioException(connectionError)을 던지고, 두 번째 호출부터는
/// 정상 응답을 돌려준다 — 단발성 네트워크 오류 재시도 동작을 검증하기 위함.
class _FlakyAdapter implements HttpClientAdapter {
  _FlakyAdapter(this.jsonBody);

  final Map<String, dynamic> jsonBody;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    if (callCount == 1) {
      throw DioException.connectionError(requestOptions: options, reason: 'timeout');
    }
    return ResponseBody.fromString(
      jsonEncode(jsonBody),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 처음 두 번은 DioException을 던지고, 세 번째 호출에서 성공한다 — 연속
/// 두 번의 네트워크 오류까지 흡수하는 동작을 검증하기 위함.
class _FlakyTwiceAdapter implements HttpClientAdapter {
  _FlakyTwiceAdapter(this.jsonBody);

  final Map<String, dynamic> jsonBody;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    if (callCount <= 2) {
      throw DioException.connectionError(requestOptions: options, reason: 'timeout');
    }
    return ResponseBody.fromString(
      jsonEncode(jsonBody),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

/// 첫 응답은 서버측 일시 오류(resultCode 05)이고, 두 번째 응답부터 정상
/// 응답을 돌려준다 — resultCode 기반 재시도 동작을 검증하기 위함.
class _TransientErrorAdapter implements HttpClientAdapter {
  _TransientErrorAdapter(this.successBody);

  final Map<String, dynamic> successBody;
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    final body = callCount == 1 ? _envelope(resultCode: '05', item: null) : successBody;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _envelope({required String resultCode, dynamic item}) {
  return {
    'response': {
      'header': {'resultCode': resultCode, 'resultMsg': resultCode == '00' ? 'NORMAL_SERVICE' : 'NO_DATA'},
      'body': {
        'items': item == null ? '' : {'item': item},
      },
    },
  };
}

void main() {
  test('getVilageFcst가 정상 응답을 DTO 리스트로 파싱함', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter(_envelope(
        resultCode: '00',
        item: [
          {'category': 'TMP', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '24'},
          {'category': 'SKY', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '1'},
        ],
      ));
    final client = KmaApiClient(dio: dio);

    final items = await client.getVilageFcst(nx: 58, ny: 126, baseDate: '20260619', baseTime: '1100');

    expect(items, hasLength(2));
    expect(items[0].category, 'TMP');
    expect(items[0].fcstValue, '24');
  });

  test('resultCode가 00이 아니면 KmaApiException을 던짐', () async {
    final dio = Dio()..httpClientAdapter = _FakeAdapter(_envelope(resultCode: '03', item: null));
    final client = KmaApiClient(dio: dio);

    expect(
      () => client.getVilageFcst(nx: 58, ny: 126, baseDate: '20260619', baseTime: '1100'),
      throwsA(isA<KmaApiException>()),
    );
  });

  test('item이 단일 객체(Map)로 와도 리스트로 정규화됨', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter(_envelope(
        resultCode: '00',
        item: {'category': 'TMP', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '24'},
      ));
    final client = KmaApiClient(dio: dio);

    final items = await client.getVilageFcst(nx: 58, ny: 126, baseDate: '20260619', baseTime: '1100');

    expect(items, hasLength(1));
  });

  test('첫 요청이 DioException(타임아웃 등)이면 한 번 재시도해서 성공함', () async {
    final adapter = _FlakyAdapter(
      _envelope(resultCode: '00', item: [
        {'category': 'TMP', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '24'},
      ]),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final client = KmaApiClient(dio: dio);

    final items = await client.getVilageFcst(nx: 58, ny: 126, baseDate: '20260619', baseTime: '1100');

    expect(items, hasLength(1));
    expect(adapter.callCount, 2);
  });

  test('연속 두 번 DioException이어도 세 번째 시도에서 성공함', () async {
    final adapter = _FlakyTwiceAdapter(
      _envelope(resultCode: '00', item: [
        {'category': 'TMP', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '24'},
      ]),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final client = KmaApiClient(dio: dio);

    final items = await client.getVilageFcst(nx: 58, ny: 126, baseDate: '20260619', baseTime: '1100');

    expect(items, hasLength(1));
    expect(adapter.callCount, 3);
  });

  test('resultCode가 서버측 일시 오류(05)면 재시도해서 성공함', () async {
    final adapter = _TransientErrorAdapter(
      _envelope(resultCode: '00', item: [
        {'category': 'TMP', 'fcstDate': '20260619', 'fcstTime': '1400', 'fcstValue': '24'},
      ]),
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final client = KmaApiClient(dio: dio);

    final items = await client.getVilageFcst(nx: 58, ny: 126, baseDate: '20260619', baseTime: '1100');

    expect(items, hasLength(1));
    expect(adapter.callCount, 2);
  });

  test('getMidLandFcst가 day별 필드를 가진 단일 객체로 파싱함', () async {
    final dio = Dio()
      ..httpClientAdapter = _FakeAdapter(_envelope(
        resultCode: '00',
        item: [
          {'regId': '11B10101', 'rnSt4Am': 70, 'rnSt4Pm': 50, 'wf4Am': '비', 'wf4Pm': '구름많음'},
        ],
      ));
    final client = KmaApiClient(dio: dio);

    final dto = await client.getMidLandFcst(regId: '11B10101', tmFc: '202606190600');

    expect(dto.regId, '11B10101');
    expect(dto.rnSt4Am, 70);
    expect(dto.rnSt4Pm, 50);
  });
}
