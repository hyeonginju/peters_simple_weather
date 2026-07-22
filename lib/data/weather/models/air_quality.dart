/// 에어코리아 통합대기환경 등급(1~4). 화면 라벨은 공식 표기를 따른다.
enum AirGrade {
  good('좋음'),
  moderate('보통'),
  bad('나쁨'),
  veryBad('매우 나쁨');

  const AirGrade(this.label);

  final String label;

  /// 백엔드가 내려준 등급 코드(1~4)를 매핑. 그 밖의 값(null·범위밖)은 null.
  static AirGrade? fromCode(int? code) => switch (code) {
        1 => AirGrade.good,
        2 => AirGrade.moderate,
        3 => AirGrade.bad,
        4 => AirGrade.veryBad,
        _ => null,
      };
}

/// 현재 미세먼지(PM10)·초미세먼지(PM2.5) 수준. 백엔드 /air-quality 응답을 매핑한다.
/// 개별 항목은 측정소 점검 등으로 빠질 수 있어 모두 nullable.
class AirQuality {
  final int? pm10;
  final AirGrade? pm10Grade;
  final int? pm25;
  final AirGrade? pm25Grade;

  const AirQuality({this.pm10, this.pm10Grade, this.pm25, this.pm25Grade});

  /// 표시할 등급이 하나라도 있는지. 둘 다 없으면 배지를 숨긴다.
  bool get hasAny => pm10Grade != null || pm25Grade != null;

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    return AirQuality(
      pm10: (json['pm10'] as num?)?.toInt(),
      pm10Grade: AirGrade.fromCode((json['pm10Grade'] as num?)?.toInt()),
      pm25: (json['pm25'] as num?)?.toInt(),
      pm25Grade: AirGrade.fromCode((json['pm25Grade'] as num?)?.toInt()),
    );
  }

  /// 디스크 캐시(SWR)용. 등급은 [AirGrade.fromCode]와 같은 1~4 코드로 되돌려
  /// [fromJson]과 라운드트립이 성립한다(enum 선언 순서 = 코드 순서).
  Map<String, dynamic> toJson() => {
        'pm10': pm10,
        'pm10Grade': pm10Grade == null ? null : pm10Grade!.index + 1,
        'pm25': pm25,
        'pm25Grade': pm25Grade == null ? null : pm25Grade!.index + 1,
      };
}
