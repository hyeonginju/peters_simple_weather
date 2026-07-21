import 'air_quality.dart';
import 'kma_forecast_item.dart';

/// "지금" 카드용 현재 날씨 데이터. 단기예보의 현재 시간 슬롯을 기반으로 하되,
/// 기온/날씨상태는 초단기실황(getUltraSrtNcst)으로 덮어쓴 값이다.
class WeatherSnapshot {
  final double temperature;
  final SkyCondition sky;
  final PrecipitationType precipitationType;
  final double precipitationAmount;
  final int precipitationProbability;

  /// 오늘 하루 총 강수량(mm) = 서버가 실측 누적한 값 + 아직 지나지 않은 시간대의
  /// 예보값. mergeTodayPrecipitationTotal 참고.
  final double todayPrecipitationTotal;

  /// 초단기실황(REH) 상대습도(%). 해당 관측치가 없으면 null.
  final int? humidity;

  /// 현재 미세먼지/초미세먼지 수준(에어코리아). 조회 실패 시 null.
  final AirQuality? airQuality;

  const WeatherSnapshot({
    required this.temperature,
    required this.sky,
    required this.precipitationType,
    required this.precipitationAmount,
    required this.precipitationProbability,
    required this.todayPrecipitationTotal,
    this.humidity,
    this.airQuality,
  });
}
