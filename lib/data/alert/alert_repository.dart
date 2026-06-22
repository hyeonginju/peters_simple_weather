import '../kma/kma_api_client.dart';
import 'kma_stn_mapper.dart';
import 'models/weather_alert.dart';

class AlertRepository {
  AlertRepository({KmaApiClient? client}) : _client = client ?? KmaApiClient();

  final KmaApiClient _client;

  /// 해당 관서(stnId) 권역의 최신 특보 통보문을 받아 발효 현황으로 가공한다.
  /// 통보문 조회 자체가 실패하면 예외를 그대로 던진다(호출부에서 에러 UI 처리).
  Future<WeatherAlertStatus> fetchByStnId(String stnId, {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    // 특보 API는 조회 기간이 최근 6일로 제한된다.
    final dto = await _client.getWthrWrnMsg(
      stnId: stnId,
      fromTmFc: _ymd(currentTime.subtract(const Duration(days: 5))),
      toTmFc: _ymd(currentTime),
    );

    final label = KmaStnMapper.labelForStnId(stnId);
    if (dto == null) {
      return WeatherAlertStatus(
        regionLabel: label,
        announcedAt: null,
        latestTitle: '',
        currentAlerts: '',
        preliminaryAlerts: '',
      );
    }

    return WeatherAlertStatus(
      regionLabel: label,
      announcedAt: _parseTmFc(dto.tmFc),
      latestTitle: (dto.t1 ?? '').trim(),
      currentAlerts: _cleanAlertText(dto.t6),
      preliminaryAlerts: _cleanAlertText(dto.t7),
    );
  }

  /// "o 없음"(중간 공백·개행 변형 포함)이면 빈 문자열로, 아니면 정리한 본문.
  static String _cleanAlertText(String? raw) {
    if (raw == null) return '';
    final normalized = raw.replaceAll('\r\n', '\n').trim();
    final compact = normalized.replaceAll(RegExp(r'\s'), '');
    // 불릿(o/ㅇ)을 떼고 "없음"만 남으면 발효 특보 없음.
    final withoutBullet = compact.replaceFirst(RegExp(r'^[oㅇO]'), '');
    if (withoutBullet == '없음' || withoutBullet.isEmpty) return '';
    return normalized;
  }

  /// yyyyMMddHHmm(int) → DateTime. 형식이 안 맞으면 null.
  static DateTime? _parseTmFc(int? tmFc) {
    if (tmFc == null) return null;
    final s = tmFc.toString();
    if (s.length != 12) return null;
    return DateTime(
      int.parse(s.substring(0, 4)),
      int.parse(s.substring(4, 6)),
      int.parse(s.substring(6, 8)),
      int.parse(s.substring(8, 10)),
      int.parse(s.substring(10, 12)),
    );
  }

  static String _ymd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }
}
