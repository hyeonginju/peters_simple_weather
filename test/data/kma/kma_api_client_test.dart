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
