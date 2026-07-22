import 'kma_forecast_item.dart';

/// Fully-resolved hourly forecast slot, ready for UI consumption — no
/// nullable weather fields, since [WeatherInterpolator] has already
/// injected defaults/carried-forward values.
class HourlyForecast {
  final DateTime time;
  final double temperature;
  final SkyCondition sky;
  final PrecipitationType precipitationType;
  final double precipitationAmount;
  final int precipitationProbability;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.sky,
    required this.precipitationType,
    required this.precipitationAmount,
    required this.precipitationProbability,
  });

  /// 디스크 캐시(SWR)용 직렬화. enum은 이름 문자열로 저장하며, 모르는 이름이
  /// 들어오면(앱 업데이트로 enum이 바뀐 옛 캐시) byName이 던져 캐시 전체를
  /// 버리게 한다 — 부분적으로 깨진 데이터를 그리는 것보다 안전하다.
  factory HourlyForecast.fromJson(Map<String, dynamic> json) => HourlyForecast(
        time: DateTime.parse(json['time'] as String),
        temperature: (json['temperature'] as num).toDouble(),
        sky: SkyCondition.values.byName(json['sky'] as String),
        precipitationType: PrecipitationType.values.byName(json['precipitationType'] as String),
        precipitationAmount: (json['precipitationAmount'] as num).toDouble(),
        precipitationProbability: (json['precipitationProbability'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'temperature': temperature,
        'sky': sky.name,
        'precipitationType': precipitationType.name,
        'precipitationAmount': precipitationAmount,
        'precipitationProbability': precipitationProbability,
      };
}
