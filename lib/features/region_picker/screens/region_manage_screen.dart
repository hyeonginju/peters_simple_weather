import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/region/models/region.dart';
import '../../../data/region/region_repository.dart';
import '../providers/region_providers.dart';

class RegionManageScreen extends ConsumerWidget {
  const RegionManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final savedRegionsAsync = ref.watch(savedRegionsProvider);

    return Scaffold(
      body: SafeArea(
        child: savedRegionsAsync.when(
          data: (regions) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '내 지역',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: palette.textPrimary),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                          decoration: BoxDecoration(color: palette.pointBg, borderRadius: BorderRadius.circular(99)),
                          child: Text('완료', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.pointText)),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 14),
                  child: Text(
                    '끌어서 순서 변경 · ${regions.length} / $maxSavedRegions 등록됨',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: palette.textMuted),
                  ),
                ),
                Expanded(child: _RegionList(regions: regions, palette: palette)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('지역을 불러오지 못했습니다: $error')),
        ),
      ),
    );
  }
}

class _RegionList extends ConsumerWidget {
  const _RegionList({required this.regions, required this.palette});

  final List<Region> regions;
  final AppPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canAdd = regions.length < maxSavedRegions;

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      itemCount: regions.length,
      proxyDecorator: (child, index, animation) => Material(color: Colors.transparent, child: child),
      footer: Column(
        children: [
          if (canAdd) ...[
            const SizedBox(height: 11),
            _AddCard(palette: palette, onTap: () => context.push('/regions/add')),
          ],
          const SizedBox(height: 14),
          _WidgetSettingsButton(palette: palette, onTap: () => context.push('/widget-settings')),
          const SizedBox(height: 10),
          _ThemeSettingsButton(palette: palette, onTap: () => context.push('/theme-settings')),
        ],
      ),
      onReorderItem: (oldIndex, newIndex) => ref.read(savedRegionsProvider.notifier).reorder(oldIndex, newIndex),
      itemBuilder: (context, index) {
        final region = regions[index];
        return Padding(
          key: ValueKey(region.id),
          padding: const EdgeInsets.only(bottom: 11),
          child: _RegionCard(
            region: region,
            index: index,
            isPrimary: index == 0,
            palette: palette,
            onDelete: () => ref.read(savedRegionsProvider.notifier).removeRegion(region.id),
          ),
        );
      },
    );
  }
}

class _WidgetSettingsButton extends StatelessWidget {
  const _WidgetSettingsButton({required this.palette, required this.onTap});

  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wallpaper_rounded, size: 18, color: palette.textSecondary),
            const SizedBox(width: 8),
            Text('위젯 설정', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: palette.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _ThemeSettingsButton extends StatelessWidget {
  const _ThemeSettingsButton({required this.palette, required this.onTap});

  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dark_mode_rounded, size: 18, color: palette.textSecondary),
            const SizedBox(width: 8),
            Text('화면 모드', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: palette.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.region,
    required this.index,
    required this.isPrimary,
    required this.palette,
    required this.onDelete,
  });

  final Region region;
  final int index;
  final bool isPrimary;
  final AppPalette palette;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            key: ValueKey('delete_${region.id}'),
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: palette.dangerBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Container(width: 11, height: 2.5, decoration: BoxDecoration(color: palette.danger, borderRadius: BorderRadius.circular(2))),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPrimary) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: palette.pointBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '대표 지역',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.pointText),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(region.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                if (region.provinceLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(region.provinceLabel!, style: TextStyle(fontSize: 12, color: palette.textMuted)),
                ],
              ],
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: 3),
                    Container(width: 15, height: 2, decoration: BoxDecoration(color: const Color(0xFFCBD0D8), borderRadius: BorderRadius.circular(1))),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.palette, required this.onTap});

  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DottedBorderBox(
        color: palette.point.withValues(alpha: 0.5),
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('+', style: TextStyle(fontSize: 19, height: 1, fontWeight: FontWeight.w600, color: palette.point)),
              const SizedBox(width: 8),
              Text('지역 추가', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: palette.point)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed rounded border (Flutter has no built-in dashed border).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, required this.color, this.radius = 12});

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color || oldDelegate.radius != radius;
}
