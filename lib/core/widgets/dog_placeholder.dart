import 'package:flutter/material.dart';

/// A cute shape-composition puppy used as a stand-in for the per-temperature
/// clothing illustrations until the user supplies real artwork. The shirt
/// colour can be tinted per clothing band so the eight bands still look
/// distinct. Built at a fixed 128×124 reference and scaled with [FittedBox].
class DogPlaceholder extends StatelessWidget {
  const DogPlaceholder({super.key, this.width = 128, this.height = 124, this.shirtColor = const Color(0xFF6E8BF5)});

  final double width;
  final double height;
  final Color shirtColor;

  static const _fur = Color(0xFFE9C9A0);
  static const _furDark = Color(0xFFC99A6A);
  static const _muzzle = Color(0xFFF6E6CC);
  static const _ink = Color(0xFF3B2F2A);
  static const _blush = Color(0x66F19494);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 128,
          height: 124,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ears (behind head)
              _ear(left: 2, top: 30, rotate: -0.35),
              _ear(left: 96, top: 30, rotate: 0.35),
              // shirt / body
              Positioned(
                left: 17,
                bottom: 0,
                child: Container(
                  width: 94,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [shirtColor.withValues(alpha: 0.92), shirtColor],
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40), bottom: Radius.circular(20)),
                  ),
                ),
              ),
              // head
              Positioned(
                left: 25,
                top: 6,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(color: _fur, borderRadius: BorderRadius.circular(34)),
                ),
              ),
              // muzzle
              Positioned(
                left: 42,
                top: 46,
                child: Container(
                  width: 44,
                  height: 32,
                  decoration: BoxDecoration(color: _muzzle, borderRadius: BorderRadius.circular(22)),
                ),
              ),
              // blush
              _dot(left: 31, top: 50, size: 13, color: _blush),
              _dot(left: 84, top: 50, size: 13, color: _blush),
              // eyes
              _dot(left: 45, top: 40, size: 9, color: _ink),
              _dot(left: 74, top: 40, size: 9, color: _ink),
              // nose
              Positioned(
                left: 59,
                top: 52,
                child: Container(
                  width: 10,
                  height: 8,
                  decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(5)),
                ),
              ),
              // mouth
              Positioned(
                left: 56,
                top: 60,
                child: Container(
                  width: 16,
                  height: 8,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _ink, width: 2)),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ear({required double left, required double top, required double rotate}) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: rotate,
        child: Container(
          width: 30,
          height: 54,
          decoration: BoxDecoration(color: _furDark, borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _dot({required double left, required double top, required double size, required Color color}) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
