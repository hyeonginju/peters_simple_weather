import 'package:flutter/material.dart';

import '../../../core/widgets/shimmer.dart';

/// Skeleton placeholder shown while a region's forecast loads (e.g. when
/// switching regions), mirroring the real content layout.
class WeatherSkeleton extends StatelessWidget {
  const WeatherSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? const Color(0xFF26282D) : const Color(0xFFE2E4E8);
    final highlight = dark ? const Color(0xFF34373D) : const Color(0xFFF0F1F4);

    return Shimmer(
      base: base,
      highlight: highlight,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const SkeletonBox(width: 96, height: 96, shape: BoxShape.circle),
            const SizedBox(height: 14),
            const SkeletonBox(width: 110, height: 52, radius: 14),
            const SizedBox(height: 14),
            const SkeletonBox(width: 150, height: 16),
            const SizedBox(height: 10),
            const SkeletonBox(width: 120, height: 14),
            const SizedBox(height: 14),
            const SkeletonBox(width: 130, height: 28, radius: 99),
            const SizedBox(height: 24),
            SkeletonBox(width: double.infinity, height: 200, radius: 24),
            const SizedBox(height: 14),
            SkeletonBox(width: double.infinity, height: 150, radius: 20),
            const SizedBox(height: 14),
            SkeletonBox(width: double.infinity, height: 300, radius: 20),
          ],
        ),
      ),
    );
  }
}
