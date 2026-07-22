import 'kma_forecast_item.dart';

/// One day's forecast card, regardless of whether it was derived from the
/// short-term (day 1-3) or mid-term (day 4-10) KMA endpoints.
class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final int popPercent;

  /// 오전(00~11시)·오후(12~23시) 강수확률. 단기예보 유래일은 시간별에서 시간대별
  /// 최댓값으로, 중기예보 유래일은 rnStAm/Pm에서 온다. 해당 시간대 데이터가 없으면 null.
  final int? amPop;
  final int? pmPop;

  /// 하루 총 강수량(mm). 단기예보가 커버하는 날(D+1~3)만 시간별 예보 합산으로
  /// 채우고, 중기예보(D+4~)는 강수량 수치를 제공하지 않아 null(화면에서 '–').
  final double? precipTotalMm;

  final SkyCondition? sky;
  final PrecipitationType? precipitationType;

  const DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.popPercent,
    this.amPop,
    this.pmPop,
    this.precipTotalMm,
    this.sky,
    this.precipitationType,
  });

  /// 디스크 캐시(SWR)용 직렬화. enum 직렬화 규칙은 [HourlyForecast.fromJson] 참고.
  factory DailyForecast.fromJson(Map<String, dynamic> json) => DailyForecast(
        date: DateTime.parse(json['date'] as String),
        minTemp: (json['minTemp'] as num).toDouble(),
        maxTemp: (json['maxTemp'] as num).toDouble(),
        popPercent: (json['popPercent'] as num).toInt(),
        amPop: (json['amPop'] as num?)?.toInt(),
        pmPop: (json['pmPop'] as num?)?.toInt(),
        precipTotalMm: (json['precipTotalMm'] as num?)?.toDouble(),
        sky: json['sky'] == null ? null : SkyCondition.values.byName(json['sky'] as String),
        precipitationType: json['precipitationType'] == null
            ? null
            : PrecipitationType.values.byName(json['precipitationType'] as String),
      );

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'minTemp': minTemp,
        'maxTemp': maxTemp,
        'popPercent': popPercent,
        'amPop': amPop,
        'pmPop': pmPop,
        'precipTotalMm': precipTotalMm,
        'sky': sky?.name,
        'precipitationType': precipitationType?.name,
      };
}

/// One day's row already extracted from getMidLandFcst (AM/PM 강수확률,
/// 날씨 텍스트) and getMidTa (최저/최고 기온) — the merger's day-4~10 input
/// contract.
class MidTermDayForecast {
  final DateTime date;
  final int amPopPercent;
  final int pmPopPercent;
  final double minTemp;
  final double maxTemp;
  final SkyCondition? sky;
  final PrecipitationType? precipitationType;

  const MidTermDayForecast({
    required this.date,
    required this.amPopPercent,
    required this.pmPopPercent,
    required this.minTemp,
    required this.maxTemp,
    this.sky,
    this.precipitationType,
  });
}
