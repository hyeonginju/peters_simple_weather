import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/weather_alert.dart';

/// 마지막으로 성공한 특보 발효 현황을 관서(stnId)별로 디스크에 보관한다
/// (stale-while-revalidate). 특보 화면 진입 시 네트워크 응답(백엔드 콜드스타트
/// 시 20초+)을 기다리지 않고 직전 통보문을 즉시 그리기 위한 저장소.
class AlertDiskCache {
  static const _keyPrefix = 'alert_cache_';

  /// 이보다 오래된 캐시는 없는 것으로 취급한다. 특보는 반나절이면 대부분
  /// 발표/해제가 갱신되므로 예보 캐시(24h)보다 짧게 잡았다 — 너무 낡은
  /// "발효 중" 표시는 즉시성이 생명인 특보에선 없느니만 못하다.
  static const maxAge = Duration(hours: 12);

  /// 저장 실패는 조용히 무시한다 — 다음 진입의 첫 화면이 느려질 뿐
  /// 이번 조회 결과에는 영향이 없다.
  Future<void> save(String stnId, WeatherAlertStatus status, DateTime fetchedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_keyPrefix$stnId',
        jsonEncode({
          'fetchedAt': fetchedAt.toIso8601String(),
          'status': status.toJson(),
        }),
      );
    } catch (_) {}
  }

  /// 저장된 현황과 그 fetch 시각. 없거나, [maxAge]를 넘었거나, 형식이 깨졌으면
  /// (앱 업데이트로 모델이 바뀐 옛 캐시 등) null — 호출부는 평소처럼 네트워크를
  /// 기다리면 된다.
  Future<({WeatherAlertStatus status, DateTime fetchedAt})?> load(String stnId, DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$stnId');
      if (raw == null) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final fetchedAt = DateTime.parse(json['fetchedAt'] as String);
      if (now.difference(fetchedAt) > maxAge) return null;

      return (
        status: WeatherAlertStatus.fromJson(json['status'] as Map<String, dynamic>),
        fetchedAt: fetchedAt,
      );
    } catch (_) {
      return null;
    }
  }
}
