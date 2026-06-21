import 'package:flutter/material.dart';

import '../../core/widgets/dog_placeholder.dart';
import 'models/clothing_band.dart';

/// Renders the clothing character for a band. If a real illustration exists
/// at `assets/images/characters/<key>.png` it's used; otherwise it falls back
/// to the tinted [DogPlaceholder]. To swap in real artwork later, just drop
/// PNGs with the matching filenames into that directory — no code change.
class CharacterArt extends StatelessWidget {
  const CharacterArt({super.key, required this.band, this.width = 128, this.height = 124});

  final ClothingBand band;
  final double width;
  final double height;

  /// Per-band shirt tint (warm for hot bands → cool for cold bands) so the
  /// eight placeholders stay visually distinct.
  static const _shirtTints = <String, Color>{
    'sleeveless_cool': Color(0xFFF2A24D),
    'short_sleeve': Color(0xFF6E8BF5),
    'long_sleeve_cardigan': Color(0xFF7BB87A),
    'hoodie_sweat': Color(0xFFB07AD6),
    'light_jacket': Color(0xFF5E9FB0),
    'trench_coat': Color(0xFFC79A5B),
    'wool_coat': Color(0xFF8A6E5C),
    'heavy_padding': Color(0xFF4A5A78),
  };

  @override
  Widget build(BuildContext context) {
    final tint = _shirtTints[band.characterAssetKey] ?? const Color(0xFF6E8BF5);
    return Image.asset(
      'assets/images/characters/${band.characterAssetKey}.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          DogPlaceholder(width: width, height: height, shirtColor: tint),
    );
  }
}
