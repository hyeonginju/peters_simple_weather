import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/data/region/models/region.dart';

void main() {
  group('Region.provinceLabel / displayName', () {
    test('일반 지역은 province를 그대로 라벨로 쓴다', () {
      const region = Region(id: '서울특별시/중구', province: '서울특별시', name: '중구', nx: 60, ny: 127);

      expect(region.provinceLabel, '서울특별시');
      expect(region.displayName, '서울특별시 중구');
    });

    test('세종처럼 province와 name이 같으면 provinceLabel은 null, displayName은 중복 없이 한 번만 표시', () {
      const region = Region(
        id: '세종특별자치시/세종특별자치시',
        province: '세종특별자치시',
        name: '세종특별자치시',
        nx: 66,
        ny: 103,
      );

      expect(region.provinceLabel, isNull);
      expect(region.displayName, '세종특별자치시');
    });
  });
}
