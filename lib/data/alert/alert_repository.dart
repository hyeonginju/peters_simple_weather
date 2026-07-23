import '../kma/kma_api_client.dart';
import 'alert_disk_cache.dart';
import 'kma_stn_mapper.dart';
import 'models/weather_alert.dart';

class AlertRepository {
  AlertRepository({KmaApiClient? client, AlertDiskCache? diskCache})
      : _client = client ?? KmaApiClient(),
        _diskCache = diskCache ?? AlertDiskCache();

  final KmaApiClient _client;
  final AlertDiskCache _diskCache;

  /// 특보 폴러(백엔드)가 5분 주기로 도니, 그보다 자주 조회해도 새 통보문이
  /// 있을 수 없다. 이 안에서는 화면 재진입 시 네트워크 없이 즉시 그린다.
  static const _ttl = Duration(minutes: 5);

  final Map<String, ({WeatherAlertStatus status, DateTime fetchedAt})> _cache = {};

  /// 메모리 캐시가 TTL 안쪽인지 — 프로바이더가 stale 경로를 탈지 결정할 때 쓴다.
  bool isFresh(String stnId, {DateTime? now}) {
    final cached = _cache[stnId];
    if (cached == null) return false;
    return (now ?? DateTime.now()).difference(cached.fetchedAt) < _ttl;
  }

  /// TTL과 무관하게 "마지막으로 성공한 현황"을 돌려준다(stale-while-revalidate).
  /// 메모리에 없으면 디스크에서 복원한다 — 없으면 null(호출부는 네트워크 대기).
  Future<WeatherAlertStatus?> staleResult(String stnId, {DateTime? now}) async {
    final cached = _cache[stnId];
    if (cached != null) return cached.status;
    final restored = await _diskCache.load(stnId, now ?? DateTime.now());
    if (restored == null) return null;
    _cache[stnId] = (status: restored.status, fetchedAt: restored.fetchedAt);
    return restored.status;
  }

  /// 수동 새로고침용 — 다음 fetch가 캐시를 건너뛰고 네트워크를 타게 한다.
  void invalidate(String stnId) => _cache.remove(stnId);

  /// 해당 관서(stnId) 권역의 최신 특보 통보문을 받아 발효 현황으로 가공한다.
  /// 통보문 조회 자체가 실패하면 예외를 그대로 던진다(호출부에서 에러 UI 처리).
  Future<WeatherAlertStatus> fetchByStnId(String stnId, {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final cached = _cache[stnId];
    if (cached != null && currentTime.difference(cached.fetchedAt) < _ttl) {
      return cached.status;
    }
    // 특보 API는 조회 기간이 최근 6일로 제한된다.
    final dto = await _client.getWthrWrnMsg(
      stnId: stnId,
      fromTmFc: _ymd(currentTime.subtract(const Duration(days: 5))),
      toTmFc: _ymd(currentTime),
    );

    final label = KmaStnMapper.labelForStnId(stnId);
    final status = dto == null
        ? WeatherAlertStatus(
            regionLabel: label,
            announcedAt: null,
            latestTitle: '',
            currentAlerts: '',
            preliminaryAlerts: '',
          )
        : WeatherAlertStatus(
            regionLabel: label,
            announcedAt: _parseTmFc(dto.tmFc),
            latestTitle: (dto.t1 ?? '').trim(),
            currentAlerts: _cleanAlertText(dto.t6),
            preliminaryAlerts: _cleanAlertText(dto.t7),
          );

    _cache[stnId] = (status: status, fetchedAt: currentTime);
    await _diskCache.save(stnId, status, currentTime);
    return status;
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
