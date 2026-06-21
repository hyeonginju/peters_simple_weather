import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// White rounded section card used for the 시간별/주간 forecast blocks on the
/// main scroll. When [onTitleTap] is set, the title row becomes tappable and
/// shows a trailing chevron (used for the 주간 예보 → chart detail link).
class ForecastSectionCard extends StatelessWidget {
  const ForecastSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.onTitleTap,
    this.titlePadding = const EdgeInsets.fromLTRB(18, 14, 18, 10),
    this.bodyPadding = EdgeInsets.zero,
  });

  final String title;
  final Widget child;
  final VoidCallback? onTitleTap;
  final EdgeInsets titlePadding;
  final EdgeInsets bodyPadding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final titleRow = Padding(
      padding: titlePadding,
      child: Row(
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary)),
          if (onTitleTap != null) ...[
            const Spacer(),
            Text('자세히', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.textMuted)),
            const SizedBox(width: 2),
            Text('›', style: TextStyle(fontSize: 16, height: 1, color: palette.textFaint)),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onTitleTap != null)
            GestureDetector(onTap: onTitleTap, behavior: HitTestBehavior.opaque, child: titleRow)
          else
            titleRow,
          Padding(padding: bodyPadding, child: child),
        ],
      ),
    );
  }
}
