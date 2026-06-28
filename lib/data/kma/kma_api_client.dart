import 'package:dio/dio.dart';

import '../alert/dto/wthr_wrn_msg_dto.dart';
import 'dto/mid_land_fcst_dto.dart';
import 'dto/mid_ta_dto.dart';
import 'dto/ultra_srt_ncst_item_dto.dart';
import 'dto/vilage_fcst_item_dto.dart';
import 'kma_api_exception.dart';
import 'kma_endpoints.dart';

class KmaApiClient {
  KmaApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
            ));

  final Dio _dio;

  static const _maxAttempts = 3;
  static const _retryDelays = [Duration(milliseconds: 800), Duration(milliseconds: 1500)];

  /// 인증/파라미터 오류 등은 재시도해도 의미가 없으므로 제외하고, 서버측
  /// 일시 오류로 보이는 resultCode만 재시도 대상으로 본다.
  static const _retryableResultCodes = {'01', '02', '04', '05', '22', '99'};

  Future<List<VilageFcstItemDto>> getVilageFcst({
    required int nx,
    required int ny,
    required String baseDate,
    required String baseTime,
  }) async {
    final items = await _getItems(KmaEndpoints.vilageFcst, {
      'nx': nx,
      'ny': ny,
      'base_date': baseDate,
      'base_time': baseTime,
    });
    return items.map(VilageFcstItemDto.fromJson).toList();
  }

  Future<List<UltraSrtNcstItemDto>> getUltraSrtNcst({
    required int nx,
    required int ny,
    required String baseDate,
    required String baseTime,
  }) async {
    final items = await _getItems(KmaEndpoints.ultraSrtNcst, {
      'nx': nx,
      'ny': ny,
      'base_date': baseDate,
      'base_time': baseTime,
    });
    return items.map(UltraSrtNcstItemDto.fromJson).toList();
  }

  Future<MidLandFcstDto> getMidLandFcst({
    required String regId,
    required String tmFc,
  }) async {
    final items = await _getItems(KmaEndpoints.midLandFcst, {'regId': regId, 'tmFc': tmFc});
    return MidLandFcstDto.fromJson(items.first);
  }

  Future<MidTaDto> getMidTa({
    required String regId,
    required String tmFc,
  }) async {
    final items = await _getItems(KmaEndpoints.midTa, {'regId': regId, 'tmFc': tmFc});
    return MidTaDto.fromJson(items.first);
  }

  /// 기상특보 통보문. 해당 관서(stnId)의 [fromTmFc]~[toTmFc](yyyyMMdd) 기간 중
  /// 가장 최근 통보문 1건. 통보문이 없으면 null.
  Future<WthrWrnMsgDto?> getWthrWrnMsg({
    required String stnId,
    required String fromTmFc,
    required String toTmFc,
  }) async {
    final items = await _getItems(KmaEndpoints.wthrWrnMsg, {
      'stnId': stnId,
      'fromTmFc': fromTmFc,
      'toTmFc': toTmFc,
    });
    return items.isEmpty ? null : WthrWrnMsgDto.fromJson(items.first);
  }

  Future<List<Map<String, dynamic>>> _getItems(
    String url,
    Map<String, dynamic> queryParameters,
  ) async {
    final response = await _requestWithRetry(url, queryParameters);

    final body = response.data!['response'] as Map<String, dynamic>;
    final header = body['header'] as Map<String, dynamic>;
    final resultCode = header['resultCode'] as String;
    if (resultCode != '00') {
      throw KmaApiException(resultCode, header['resultMsg'] as String);
    }

    final items = (body['body'] as Map<String, dynamic>)['items'];
    if (items is! Map<String, dynamic>) {
      return [];
    }
    final item = items['item'];
    if (item is List) {
      return item.cast<Map<String, dynamic>>();
    }
    if (item is Map<String, dynamic>) {
      return [item];
    }
    return [];
  }

  /// 백엔드 프록시도 간헐적 타임아웃/연결 오류나 서버측 일시 오류
  /// (resultCode가 [_retryableResultCodes]에 속하는 경우)가 날 수 있어, 최대
  /// [_maxAttempts]번까지 흡수한다. 인증/파라미터 오류 등 재시도해도 의미
  /// 없는 resultCode는 그대로 반환해 [_getItems]에서 예외로 던지게 한다.
  Future<Response<Map<String, dynamic>>> _requestWithRetry(
    String url,
    Map<String, dynamic> queryParameters,
  ) async {
    for (var attempt = 1;; attempt++) {
      try {
        final response = await _dio.get<Map<String, dynamic>>(url, queryParameters: queryParameters);
        if (attempt >= _maxAttempts || !_isRetryableResultCode(response)) {
          return response;
        }
        await Future.delayed(_retryDelays[attempt - 1]);
      } on DioException {
        if (attempt >= _maxAttempts) rethrow;
        await Future.delayed(_retryDelays[attempt - 1]);
      }
    }
  }

  bool _isRetryableResultCode(Response<Map<String, dynamic>> response) {
    final resultCode =
        (response.data?['response'] as Map<String, dynamic>?)?['header']?['resultCode'] as String?;
    return resultCode != null && _retryableResultCodes.contains(resultCode);
  }
}
