import 'kma_forecast_item.dart';

/// "지금" 카드용 현재 날씨 데이터. 단기예보의 현재 시간 슬롯을 기반으로 하되,
/// 기온/날씨상태는 초단기실황(getUltraSrtNcst)으로 덮어쓴 값이다.
class WeatherSnapshot {
  final double temperature;
  final SkyCondition sky;
  final PrecipitationType precipitationType;
  final double precipitationAmount;
  final int precipitationProbability;

  /// 초단기실황(REH) 상대습도(%). 해당 관측치가 없으면 null.
  final int? humidity;

  /// 오늘 하루 총 강수량(mm). 지역이 오늘 처음 조회됐으면(로컬에 실측 데이터가
  /// 아직 없으면) 순수 예보 합산, 아니면 실측+남은 예보 하이브리드 합산.
  /// mergeTodayPrecipitationTotal/sumPrecipitationToday 참고.
  final double todayPrecipitationTotal;

  const WeatherSnapshot({
    required this.temperature,
    required this.sky,
    required this.precipitationType,
    required this.precipitationAmount,
    required this.precipitationProbability,
    required this.todayPrecipitationTotal,
    this.humidity,
  });
}
