import '../models/hourly_forecast.dart';

/// 오늘 하루 누적 강수량(mm). 메인 화면의 "현재 비/눈이 오고 있을 때" 강조
/// 블록에 사용한다 (기획서 2.2 4번).
double sumPrecipitationToday(List<HourlyForecast> hourly, DateTime date) {
  return hourly
      .where((h) => h.time.year == date.year && h.time.month == date.month && h.time.day == date.day)
      .fold(0.0, (sum, h) => sum + h.precipitationAmount);
}
