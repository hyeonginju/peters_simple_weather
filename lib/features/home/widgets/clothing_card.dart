import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../clothing/models/clothing_band.dart';

class ClothingCard extends StatelessWidget {
  const ClothingCard({super.key, required this.band});

  final ClothingBand band;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  band.headline,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: palette.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: palette.pointBg, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  band.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: palette.pointText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            band.guideline,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.5, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
