import 'package:dio/dio.dart';

import '../../core/env/env.dart';
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

  Future<List<Map<String, dynamic>>> _getItems(
    String url,
    Map<String, dynamic> queryParameters,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      url,
      queryParameters: {
        'serviceKey': Env.kmaServiceKey,
        'dataType': 'JSON',
        'pageNo': 1,
        ...queryParameters,
      },
    );

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
