import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/weather_icon.dart';

/// 전체 장애 화면 — 네트워크/기상청 API 마비 시. Matches the handoff mock:
/// a soft circular badge with the rain icon, the standard error copy, and an
/// indigo 다시 시도 button.
class ErrorFullScreen extends StatelessWidget {
  const ErrorFullScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEFF3),
              ),
              alignment: Alignment.center,
              child: const WeatherIcon(type: WeatherIconType.rain, size: 92),
            ),
            const SizedBox(height: 26),
            Text(
              '기상청 서버에서 데이터를\n불러오지 못했습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.45, color: palette.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              '잠시 후 다시 시도해 주세요.',
              style: TextStyle(fontSize: 14, color: palette.textMuted),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                decoration: BoxDecoration(
                  color: palette.point,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: palette.point.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 17, color: Colors.white),
                    SizedBox(width: 8),
                    Text('다시 시도', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
