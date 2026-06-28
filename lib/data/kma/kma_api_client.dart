import 'package:dio/dio.dart';

import '../../core/env/env.dart';
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
      'numOfRows': 1000,
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
      'numOfRows': 100,
    });
    return items.map(UltraSrtNcstItemDto.fromJson).toList();
  }

  Future<MidLandFcstDto> getMidLandFcst({
    required String regId,
    required String tmFc,
  }) async {
    final items = await _getItems(KmaEndpoints.midLandFcst, {
      'regId': regId,
      'tmFc': tmFc,
      'numOfRows': 10,
    });
    return MidLandFcstDto.fromJson(items.first);
  }

  Future<MidTaDto> getMidTa({
    required String regId,
    required String tmFc,
  }) async {
    final items = await _getItems(KmaEndpoints.midTa, {
      'regId': regId,
      'tmFc': tmFc,
      'numOfRows': 10,
    });
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
      'numOfRows': 1,
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

  /// 기상청 공개 API는 간헐적으로 타임아웃/연결 오류가 나는 일이 잦아, 단발성
  /// 네트워크 오류(DioException) 한 번은 재시도해서 흡수한다. resultCode 기반
  /// 응답 오류(KmaApiException)는 정상 응답이므로 재시도하지 않는다.
  Future<Response<Map<String, dynamic>>> _requestWithRetry(
    String url,
    Map<String, dynamic> queryParameters,
  ) async {
    final params = {
      'serviceKey': Env.kmaServiceKey,
      'dataType': 'JSON',
      'pageNo': 1,
      ...queryParameters,
    };
    try {
      return await _dio.get<Map<String, dynamic>>(url, queryParameters: params);
    } on DioException {
      await Future.delayed(const Duration(milliseconds: 800));
      return await _dio.get<Map<String, dynamic>>(url, queryParameters: params);
    }
  }
}
