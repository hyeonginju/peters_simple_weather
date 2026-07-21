import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/weather/models/air_quality.dart';

void main() {
  group('AirGrade.fromCode', () {
    test('1~4를 등급으로 매핑', () {
      expect(AirGrade.fromCode(1), AirGrade.good);
      expect(AirGrade.fromCode(2), AirGrade.moderate);
      expect(AirGrade.fromCode(3), AirGrade.bad);
      expect(AirGrade.fromCode(4), AirGrade.veryBad);
    });

    test('null·범위밖은 null', () {
      expect(AirGrade.fromCode(null), isNull);
      expect(AirGrade.fromCode(0), isNull);
      expect(AirGrade.fromCode(5), isNull);
    });
  });

  group('AirQuality.fromJson', () {
    test('수치와 등급을 파싱', () {
      final air = AirQuality.fromJson({'pm10': 42, 'pm10Grade': 2, 'pm25': 18, 'pm25Grade': 1});
      expect(air.pm10, 42);
      expect(air.pm10Grade, AirGrade.moderate);
      expect(air.pm25, 18);
      expect(air.pm25Grade, AirGrade.good);
      expect(air.hasAny, isTrue);
    });

    test('등급이 없으면 null, hasAny=false', () {
      final air = AirQuality.fromJson({'pm10': null, 'pm10Grade': null, 'pm25': null, 'pm25Grade': null});
      expect(air.pm10Grade, isNull);
      expect(air.pm25Grade, isNull);
      expect(air.hasAny, isFalse);
    });

    test('한쪽 등급만 있어도 hasAny=true', () {
      final air = AirQuality.fromJson({'pm10Grade': 3});
      expect(air.pm10Grade, AirGrade.bad);
      expect(air.pm25Grade, isNull);
      expect(air.hasAny, isTrue);
    });
  });
}
