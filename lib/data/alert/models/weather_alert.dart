/// 화면에 보여줄 가공된 특보 발효 현황(특정 관서 권역의 최신 통보문 기준).
class WeatherAlertStatus {
  const WeatherAlertStatus({
    required this.regionLabel,
    required this.announcedAt,
    required this.latestTitle,
    required this.currentAlerts,
    required this.preliminaryAlerts,
  });

  /// 권역 표시명(예: "대전·세종·충남", "전국").
  final String regionLabel;

  /// 통보문 발표 시각. 파싱 실패 시 null.
  final DateTime? announcedAt;

  /// 최근 발표/해제 제목(t1).
  final String latestTitle;

  /// 현재 발효 중인 특보 본문. 없으면 빈 문자열.
  final String currentAlerts;

  /// 예비특보 본문. 없으면 빈 문자열.
  final String preliminaryAlerts;

  /// 현재 발효 중인 특보가 있는지.
  bool get hasActiveAlert => currentAlerts.isNotEmpty;
}
