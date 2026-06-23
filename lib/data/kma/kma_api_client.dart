import 'package:dio/dio.dart';

import '../alert/dto/wthr_wrn_msg_dto.dart';
import 'dto/mid_land_fcst_dto.dart';
import 'dto/mid_ta_dto.dart';
import 'dto/ultra_srt_ncst_item_dto.dart';
import 'dto/vilage_fcst_item_dto.dart';
import 'kma_api_exception.dart';
import 'kma_endpoints.dart';

class KmaApiClient {
  KmaApiClient({Dio? dio}) : _dio = dio ?? Dio();

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
    final response = await _dio.get<Map<String, dynamic>>(url, queryParameters: queryParameters);

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
}
