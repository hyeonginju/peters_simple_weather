import '../models/hourly_forecast.dart';

/// 오늘 하루 누적 강수량(mm). 메인 화면의 "현재 비/눈이 오고 있을 때" 강조
/// 블록에 사용한다 (기획서 2.2 4번).
///
/// 이미 지나간 시간대는 예보값이 아니라 서버가 초단기실황 RN1로 실측 누적한
/// [observedRn](00시~마지막 관측 시간대까지)을 쓰고, 아직 다 지나지 않은 시간대
/// (현재 시각이 속한 시간부터 이후)만 예보값을 합산한다 — 두 구간을 시간 경계로
/// 나눠 이중 계산을 피한다.
double mergeTodayPrecipitationTotal(double observedRn, List<HourlyForecast> hourly, DateTime now) {
  final currentHourStart = DateTime(now.year, now.month, now.day, now.hour);
  final remainingForecast = hourly
      .where((h) =>
          h.time.year == now.year &&
          h.time.month == now.month &&
          h.time.day == now.day &&
          !h.time.isBefore(currentHourStart))
      .fold(0.0, (sum, h) => sum + h.precipitationAmount);
  return observedRn + remainingForecast;
}
