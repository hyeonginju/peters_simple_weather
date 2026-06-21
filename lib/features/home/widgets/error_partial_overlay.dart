import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Blurred glassmorphism overlay for a single failed component (e.g. only the
/// hourly or only the weekly section failed to parse) without taking down the
/// rest of the screen. Matches the 부분 장애 mock from the handoff.
class ErrorPartialOverlay extends StatelessWidget {
  const ErrorPartialOverlay({super.key, required this.child, required this.message, this.onTap});

  final Widget child;
  final String message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final lines = message.split('\n');

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 15, color: palette.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            lines.first,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textSecondary),
                          ),
                        ],
                      ),
                      if (lines.length > 1) ...[
                        const SizedBox(height: 6),
                        Text(
                          lines.sublist(1).join('\n'),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: palette.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
