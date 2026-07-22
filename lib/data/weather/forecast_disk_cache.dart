import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/daily_forecast.dart';
import 'models/forecast_result.dart';
import 'models/hourly_forecast.dart';
import 'models/weather_snapshot.dart';

/// 마지막으로 성공한 예보 결과를 지역별로 디스크에 보관한다(stale-while-revalidate).
/// 앱 프로세스가 새로 시작돼 메모리 캐시가 비어 있을 때, 네트워크 응답(백엔드
/// 콜드스타트 시 20초+)을 기다리지 않고 직전 데이터를 즉시 그리기 위한 저장소.
class ForecastDiskCache {
  static const _keyPrefix = 'forecast_cache_';

  /// 이보다 오래된 캐시는 없는 것으로 취급한다. 시간별 예보 창(+3일)을 크게
  /// 벗어난 데이터는 현재 시각 기준으로 재배치해도 그릴 내용이 없다.
  static const maxAge = Duration(hours: 24);

  /// 부분 실패(hourly/daily 누락)는 저장하지 않는다 — 다음 성공 결과가 남는
  /// 쪽이 첫 화면 데이터로 더 낫다. 저장 실패는 조용히 무시한다 — 다음 실행의
  /// 첫 화면이 느려질 뿐 이번 fetch 결과에는 영향이 없다.
  Future<void> save(String regionId, ForecastSuccess result, DateTime fetchedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_keyPrefix$regionId',
        jsonEncode({
          'fetchedAt': fetchedAt.toIso8601String(),
          'snapshot': result.snapshot.toJson(),
          'hourly': [for (final h in result.hourly) h.toJson()],
          'daily': [for (final d in result.daily) d.toJson()],
        }),
      );
    } catch (_) {}
  }

  /// 저장된 결과와 그 fetch 시각. 없거나, [maxAge]를 넘었거나, 형식이 깨졌으면
  /// (앱 업데이트로 모델이 바뀐 옛 캐시 등) null — 호출부는 평소처럼 네트워크를
  /// 기다리면 된다.
  Future<({ForecastSuccess result, DateTime fetchedAt})?> load(String regionId, DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$regionId');
      if (raw == null) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final fetchedAt = DateTime.parse(json['fetchedAt'] as String);
      if (now.difference(fetchedAt) > maxAge) return null;

      final result = ForecastSuccess(
        snapshot: WeatherSnapshot.fromJson(json['snapshot'] as Map<String, dynamic>),
        hourly: [
          for (final h in json['hourly'] as List) HourlyForecast.fromJson(h as Map<String, dynamic>),
        ],
        daily: [
          for (final d in json['daily'] as List) DailyForecast.fromJson(d as Map<String, dynamic>),
        ],
      );
      return (result: result, fetchedAt: fetchedAt);
    } catch (_) {
      return null;
    }
  }
}
