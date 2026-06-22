import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

class RegionHeader extends StatelessWidget {
  const RegionHeader({
    super.key,
    required this.provinceName,
    required this.regionName,
    required this.pageCount,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
  });

  final String? provinceName;
  final String regionName;
  final int pageCount;
  final int currentIndex;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Chevron(icon: '‹', onTap: onPrevious, palette: palette),
            const SizedBox(width: 20),
            Column(
              children: [
                if (provinceName != null) ...[
                  Text(
                    provinceName!,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textMuted),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  regionName,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: palette.textPrimary),
                ),
              ],
            ),
            const SizedBox(width: 20),
            _Chevron(icon: '›', onTap: onNext, palette: palette),
          ],
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < pageCount; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: i == currentIndex ? palette.point : palette.dotInactive,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.icon, required this.onTap, required this.palette});

  final String icon;
  final VoidCallback? onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          icon,
          style: TextStyle(
            fontSize: 24,
            height: 1,
            color: onTap == null ? palette.textFaint.withValues(alpha: 0.4) : palette.textFaint,
          ),
        ),
      ),
    );
  }
}
