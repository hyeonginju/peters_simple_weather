import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum WeatherIconType { sun, partly, cloud, rain, snow }

/// Recreates the shape-composition weather icons from the Claude Design
/// handoff (`WeatherIcon.dc.html`) as a scalable [CustomPaint], so no raster
/// asset is needed. All geometry is expressed as a fraction of [size].
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({super.key, required this.type, this.size = 104});

  final WeatherIconType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _WeatherIconPainter(type)),
    );
  }
}

class _WeatherIconPainter extends CustomPainter {
  _WeatherIconPainter(this.type);

  final WeatherIconType type;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    switch (type) {
      case WeatherIconType.sun:
        _drawSun(canvas, s, Offset(s / 2, s / 2), s * 0.56);
      case WeatherIconType.partly:
        _drawSun(canvas, s, Offset(s * 0.37, s * 0.31), s * 0.46, withRays: false);
        _drawCloud(
          canvas,
          Rect.fromLTWH(s * 0.08, s * 0.36, s * 0.84, s * 0.50),
          const _CloudColors(AppColors.cloudA, AppColors.cloudB, AppColors.cloudC),
        );
      case WeatherIconType.cloud:
        _drawCloud(
          canvas,
          Rect.fromLTWH(s * 0.08, s * 0.21, s * 0.84, s * 0.58),
          const _CloudColors(AppColors.cloudA, AppColors.cloudB, AppColors.cloudC),
        );
      case WeatherIconType.rain:
        _drawCloud(
          canvas,
          Rect.fromLTWH(s * 0.08, s * 0.06, s * 0.84, s * 0.50),
          const _CloudColors(AppColors.cloudRainA, AppColors.cloudRainB, AppColors.cloudRainC),
        );
        _drawDrops(canvas, s);
      case WeatherIconType.snow:
        _drawCloud(
          canvas,
          Rect.fromLTWH(s * 0.08, s * 0.06, s * 0.84, s * 0.50),
          const _CloudColors(AppColors.cloudA, AppColors.cloudB, AppColors.cloudC),
        );
        _drawSnow(canvas, s);
    }
  }

  void _drawSun(Canvas canvas, double s, Offset center, double diameter, {bool withRays = true}) {
    final radius = diameter / 2;

    if (withRays) {
      final rayPaint = Paint()..color = AppColors.sunRay;
      final rayW = s * 0.08;
      final rayH = s * 0.22;
      final rayDist = rayH * 1.65; // CSS translateY(-165%) of own height
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        canvas.translate(0, -rayDist);
        final rect = Rect.fromCenter(center: Offset.zero, width: rayW, height: rayH);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(rayW / 2)), rayPaint);
        canvas.restore();
      }
    }

    final corePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment(-0.5, -1),
        end: Alignment(0.6, 1),
        colors: [AppColors.sunCoreTop, AppColors.sunCoreBottom],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, corePaint);
  }

  void _drawCloud(Canvas canvas, Rect box, _CloudColors c) {
    final w = box.width;
    final h = box.height;
    double px(double f) => box.left + w * f;
    double py(double f) => box.top + h * f;

    final bottomLeftPaint = Paint()..color = c.bottomLeft;
    final rightPaint = Paint()..color = c.right;
    final topPaint = Paint()..color = c.top;

    // bottom bar (capsule): x 4%..96%, y 48%..100%
    final bar = Rect.fromLTRB(px(0.04), py(0.48), px(0.96), py(1.0));
    canvas.drawRRect(RRect.fromRectAndRadius(bar, Radius.circular(bar.height / 2)), bottomLeftPaint);
    // left puff: x 2%..50%, y 12%..78%
    canvas.drawOval(Rect.fromLTRB(px(0.02), py(0.12), px(0.50), py(0.78)), bottomLeftPaint);
    // right puff: x 53%..95%, y 16%..74%
    canvas.drawOval(Rect.fromLTRB(px(0.53), py(0.16), px(0.95), py(0.74)), rightPaint);
    // top puff: x 28%..80%, y -18%..66%
    canvas.drawOval(Rect.fromLTRB(px(0.28), py(-0.18), px(0.80), py(0.66)), topPaint);
  }

  void _drawDrops(Canvas canvas, double s) {
    final paint = Paint()..color = AppColors.rainDrop;
    final dropW = s * 0.075;
    final heights = [s * 0.17, s * 0.21, s * 0.17];
    final baseY = s * 0.80;
    final centerX = s * 0.5;
    final gap = s * 0.18;
    for (var i = 0; i < 3; i++) {
      final dx = centerX + (i - 1) * gap;
      canvas.save();
      canvas.translate(dx, baseY);
      canvas.rotate(12 * math.pi / 180);
      final rect = Rect.fromCenter(center: Offset.zero, width: dropW, height: heights[i]);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(dropW / 2)), paint);
      canvas.restore();
    }
  }

  void _drawSnow(Canvas canvas, double s) {
    final paint = Paint()..color = AppColors.snowFlake;
    final r = s * 0.045;
    final baseY = s * 0.82;
    final centerX = s * 0.5;
    final gap = s * 0.18;
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(centerX + (i - 1) * gap, baseY), r, paint);
    }
  }

  @override
  bool shouldRepaint(_WeatherIconPainter oldDelegate) => oldDelegate.type != type;
}

class _CloudColors {
  const _CloudColors(this.bottomLeft, this.right, this.top);
  final Color bottomLeft;
  final Color right;
  final Color top;
}
