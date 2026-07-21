import '../models/hourly_forecast.dart';

/// 오늘 예상 강수량(mm) — 단기예보의 오늘 시간별 예보값을 합산한다.
/// 단기예보 응답은 현재 시각 근처부터의 시간대만 주므로(이미 지난 새벽 시간대는
/// 응답에 없음) 실질적으로 "현재~자정" 예보 합이다. 백엔드가 없는 solo에서는
/// 앱 사용에 좌우되는 실측 누적 대신 이 결정적인 예보값을 쓴다.
double sumPrecipitationToday(List<HourlyForecast> hourly, DateTime date) {
  return hourly
      .where((h) => h.time.year == date.year && h.time.month == date.month && h.time.day == date.day)
      .fold(0.0, (sum, h) => sum + h.precipitationAmount);
}
