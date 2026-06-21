import 'models/clothing_band.dart';

/// 환절기/동절기: 11~4월. 하절기: 5~10월.
const _transitionOrWinterMonths = {11, 12, 1, 2, 3, 4};
const _summerMonths = {5, 6, 7, 8, 9, 10};

/// Resolves T_target per the spec's ΔT decision logic:
/// - ΔT≥15 & 환절기/동절기 → T_min (추위 대비 우선)
/// - ΔT≥15 & 하절기 → T_max (폭염 대비 우선)
/// - 그 외 → 낮 시간대(09-18시) 평균 기온
double resolveTargetTemperature({
  required double maxTemp,
  required double minTemp,
  required double daytimeAverageTemp,
  required int month,
}) {
  final deltaT = maxTemp - minTemp;

  if (deltaT >= 15 && _transitionOrWinterMonths.contains(month)) {
    return minTemp;
  }
  if (deltaT >= 15 && _summerMonths.contains(month)) {
    return maxTemp;
  }
  return daytimeAverageTemp;
}

/// 대한민국 표준 날씨별 옷차림 매핑 기준 (기획서 3.2), 높은 온도 구간부터 정렬.
const _bands = <(double, ClothingBand)>[
  (
    28,
    ClothingBand(
      label: '28° 이상',
      headline: '시원하게 입어요',
      guideline: '민소매, 반바지, 린넨 옷, 원피스, 얇은 치마',
      characterAssetKey: 'sleeveless_cool',
    ),
  ),
  (
    23,
    ClothingBand(
      label: '23~27°',
      headline: '가볍게 입기 좋아요',
      guideline: '반팔, 얇은 셔츠, 반바지, 면바지',
      characterAssetKey: 'short_sleeve',
    ),
  ),
  (
    20,
    ClothingBand(
      label: '20~22°',
      headline: '선선해요',
      guideline: '긴팔티, 가디건, 면바지, 슬랙스, 얇은 후드티',
      characterAssetKey: 'long_sleeve_cardigan',
    ),
  ),
  (
    17,
    ClothingBand(
      label: '17~19°',
      headline: '긴팔이 좋아요',
      guideline: '니트, 맨투맨, 후드티, 청바지, 가디건',
      characterAssetKey: 'hoodie_sweat',
    ),
  ),
  (
    12,
    ClothingBand(
      label: '12~16°',
      headline: '겉옷을 챙겨요',
      guideline: '자켓, 셔츠, 가디건, 청바지, 스타킹, 가벼운 외투',
      characterAssetKey: 'light_jacket',
    ),
  ),
  (
    9,
    ClothingBand(
      label: '9~11°',
      headline: '외투가 필요해요',
      guideline: '트렌치코트, 야상, 자켓, 기모바지, 니트',
      characterAssetKey: 'trench_coat',
    ),
  ),
  (
    5,
    ClothingBand(
      label: '5~8°',
      headline: '따뜻하게 입어요',
      guideline: '울 코트, 가죽 자켓, 가디건 레이어드, 내의',
      characterAssetKey: 'wool_coat',
    ),
  ),
  (
    double.negativeInfinity,
    ClothingBand(
      label: '4° 이하',
      headline: '단단히 챙겨 입어요',
      guideline: '패딩, 두꺼운 코트, 기모 제품, 목도리, 장갑',
      characterAssetKey: 'heavy_padding',
    ),
  ),
];

ClothingBand mapTemperatureToClothingBand(double targetTemp) {
  for (final (minInclusive, band) in _bands) {
    if (targetTemp >= minInclusive) {
      return band;
    }
  }
  return _bands.last.$2;
}
