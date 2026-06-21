import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/core/utils/pcp_parser.dart';

void main() {
  group('parsePrecipitationAmount', () {
    test('강수없음 → 0.0', () {
      expect(parsePrecipitationAmount('강수없음'), 0.0);
    });

    test('1mm 미만 → 0.5', () {
      expect(parsePrecipitationAmount('1mm 미만'), 0.5);
    });

    test('범위형 "30~50mm" → 평균값 40.0', () {
      expect(parsePrecipitationAmount('30~50mm'), 40.0);
    });

    test('"50mm 이상" → 정규식으로 추출한 50.0', () {
      expect(parsePrecipitationAmount('50mm 이상'), 50.0);
    });

    test('"30mm 이상" 같은 다른 임계값도 일반화되어 추출됨', () {
      expect(parsePrecipitationAmount('30mm 이상'), 30.0);
    });

    test('단순 숫자 문자열도 파싱됨', () {
      expect(parsePrecipitationAmount('5'), 5.0);
    });

    test('빈 문자열은 0.0', () {
      expect(parsePrecipitationAmount(''), 0.0);
    });
  });
}
