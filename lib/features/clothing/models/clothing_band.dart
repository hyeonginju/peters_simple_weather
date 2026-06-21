class ClothingBand {
  /// Temperature-range label, e.g. "23~27°".
  final String label;

  /// Short cheery title shown as the card headline, e.g. "가볍게 입기 좋아요".
  final String headline;

  /// Clothing keyword detail, e.g. "반팔, 얇은 셔츠, 반바지, 면바지".
  final String guideline;

  /// Key into `assets/images/characters/<key>.png`.
  final String characterAssetKey;

  const ClothingBand({
    required this.label,
    required this.headline,
    required this.guideline,
    required this.characterAssetKey,
  });
}
