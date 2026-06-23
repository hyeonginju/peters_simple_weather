import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/weather_icon.dart';

/// 전체 장애 화면 — 네트워크/기상청 API 마비 시. Matches the handoff mock:
/// a soft circular badge with the rain icon, the standard error copy, and an
/// indigo 다시 시도 button.
///
/// [onRetry] returns a future so the button can show an in-flight spinner and
/// block re-taps until the re-fetch settles. Without this feedback a failed
/// retry redraws the identical screen instantly and looks like a dead button.
class ErrorFullScreen extends StatefulWidget {
  const ErrorFullScreen({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<ErrorFullScreen> createState() => _ErrorFullScreenState();
}

class _ErrorFullScreenState extends State<ErrorFullScreen> {
  bool _retrying = false;

  Future<void> _handleRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } catch (_) {
      // 재요청이 또 실패해도 에러 화면이 그대로 유지되면 된다 — 삼켜서 스피너만 끈다.
    } finally {
      // 성공 시엔 이 위젯이 트리에서 사라지므로 mounted 가드가 필요하다.
      if (mounted) setState(() => _retrying = false);
    }
  }

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
              _retrying ? '데이터를 불러오는 중…' : '잠시 후 다시 시도해 주세요.',
              style: TextStyle(fontSize: 14, color: palette.textMuted),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _retrying ? null : _handleRetry,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                decoration: BoxDecoration(
                  color: _retrying ? palette.point.withValues(alpha: 0.7) : palette.point,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: palette.point.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_retrying)
                      const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(Icons.refresh_rounded, size: 17, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _retrying ? '불러오는 중' : '다시 시도',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
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
