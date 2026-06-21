import 'package:flutter_test/flutter_test.dart';
import 'package:peters_simple_weather/features/clothing/clothing_band_mapper.dart';

void main() {
  group('resolveTargetTemperature', () {
    test('ΔT≥15 & 환절기/동절기(예: 3월) → T_min 사용 (추위 대비)', () {
      final target = resolveTargetTemperature(
        maxTemp: 20,
        minTemp: 3,
        daytimeAverageTemp: 12,
        month: 3,
      );
      expect(target, 3);
    });

    test('ΔT≥15 & 하절기(예: 7월) → T_max 사용 (폭염 대비)', () {
      final target = resolveTargetTemperature(
        maxTemp: 33,
        minTemp: 17,
        daytimeAverageTemp: 25,
        month: 7,
      );
      expect(target, 33);
    });

    test('ΔT<15 → 낮 시간대 평균 기온 사용', () {
      final target = resolveTargetTemperature(
        maxTemp: 25,
        minTemp: 18,
        daytimeAverageTemp: 22,
        month: 5,
      );
      expect(target, 22);
    });

    test('ΔT≥15 & 11월(환절기) → T_min 사용', () {
      final target = resolveTargetTemperature(
        maxTemp: 22,
        minTemp: 5,
        daytimeAverageTemp: 14,
        month: 11,
      );
      expect(target, 5);
    });
  });

  group('mapTemperatureToClothingBand', () {
    test('28도 이상 → 민소매 밴드', () {
      expect(mapTemperatureToClothingBand(30).characterAssetKey, 'sleeveless_cool');
      expect(mapTemperatureToClothingBand(28).characterAssetKey, 'sleeveless_cool');
    });

    test('23~27도 → 반팔 밴드', () {
      expect(mapTemperatureToClothingBand(27).characterAssetKey, 'short_sleeve');
      expect(mapTemperatureToClothingBand(23).characterAssetKey, 'short_sleeve');
    });

    test('20~22도 → 긴팔 가디건 밴드', () {
      expect(mapTemperatureToClothingBand(22).characterAssetKey, 'long_sleeve_cardigan');
    });

    test('17~19도 → 니트/맨투맨 밴드', () {
      expect(mapTemperatureToClothingBand(18).characterAssetKey, 'hoodie_sweat');
    });

    test('12~16도 → 자켓 밴드', () {
      expect(mapTemperatureToClothingBand(14).characterAssetKey, 'light_jacket');
    });

    test('9~11도 → 트렌치코트 밴드', () {
      expect(mapTemperatureToClothingBand(10).characterAssetKey, 'trench_coat');
    });

    test('5~8도 → 울 코트 밴드', () {
      expect(mapTemperatureToClothingBand(6).characterAssetKey, 'wool_coat');
    });

    test('4도 이하 → 패딩 밴드', () {
      expect(mapTemperatureToClothingBand(4).characterAssetKey, 'heavy_padding');
      expect(mapTemperatureToClothingBand(-10).characterAssetKey, 'heavy_padding');
    });
  });
}
