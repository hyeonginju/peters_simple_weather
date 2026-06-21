import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/weather_icon_mapper.dart';
import '../../../core/widgets/weather_icon.dart';
import '../../../data/weather/models/daily_forecast.dart';
import '../../../data/weather/models/kma_forecast_item.dart';

/// 주간 예보 B안 — 최고/최저 기온 추세 선그래프 + 범위 밴드. Faithful
/// recreation of the handoff's SVG chart: a CustomPaint draws the band, the
/// two polylines and the node dots, while temperature/day/date labels and the
/// weather icons are positioned widgets on top (as in the source).
class WeeklyTrendChart extends StatelessWidget {
  const WeeklyTrendChart({super.key, required this.daily, required this.today});

  final List<DailyForecast> daily;
  final DateTime today;

  static const _lineAreaHeight = 150.0;
  static const _chartTop = 30.0;
  static const _chartBottom = 124.0;
  static const _leftPad = 24.0;
  static const _rightPad = 24.0;
  static const _bottomColumnTop = 158.0;
  static const _totalHeight = 236.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final lows = daily.map((d) => d.minTemp);
    final highs = daily.map((d) => d.maxTemp);
    final cMin = lows.reduce((a, b) => a < b ? a : b) - 2;
    final cMax = highs.reduce((a, b) => a > b ? a : b) + 3;
    final range = (cMax - cMin).clamp(1, double.infinity);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final usable = width - _leftPad - _rightPad;
        final step = daily.length > 1 ? usable / (daily.length - 1) : 0.0;

        double xOf(int i) => _leftPad + i * step;
        double yOf(double t) => _chartTop + (cMax - t) / range * (_chartBottom - _chartTop);

        final points = [
          for (var i = 0; i < daily.length; i++)
            _ChartPoint(
              x: xOf(i),
              yHigh: yOf(daily[i].maxTemp),
              yLow: yOf(daily[i].minTemp),
              day: daily[i],
            ),
        ];

        return SizedBox(
          height: _totalHeight,
          width: width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _lineAreaHeight,
                child: CustomPaint(
                  painter: _ChartPainter(points: points, palette: palette),
                ),
              ),
              for (final p in points) ..._labelsFor(p, palette),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _labelsFor(_ChartPoint p, AppPalette palette) {
    final sky = p.day.sky ?? SkyCondition.clear;
    final pty = p.day.precipitationType ?? PrecipitationType.none;
    return [
      // high temp label (above the high dot)
      Positioned(
        left: p.x - 20,
        top: p.yHigh - 22,
        width: 40,
        child: Text(
          '${p.day.maxTemp.round()}°',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.textPrimary),
        ),
      ),
      // low temp label (below the low dot)
      Positioned(
        left: p.x - 20,
        top: p.yLow + 6,
        width: 40,
        child: Text(
          '${p.day.minTemp.round()}°',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.textMuted),
        ),
      ),
      // bottom column: icon / day / date / pop
      Positioned(
        left: p.x - 24,
        top: _bottomColumnTop,
        width: 48,
        child: Column(
          children: [
            WeatherIcon(type: weatherIconTypeFor(sky, pty), size: 26),
            const SizedBox(height: 3),
            Text(
              formatWeeklyDayLabel(p.day.date, today: today).split(' ').first,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary),
            ),
            const SizedBox(height: 1),
            Text(
              '${p.day.date.month}.${p.day.date.day}',
              style: TextStyle(fontSize: 10.5, color: palette.textMuted),
            ),
            const SizedBox(height: 1),
            Text(
              '${p.day.popPercent}%',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.rain),
            ),
          ],
        ),
      ),
    ];
  }
}

class _ChartPoint {
  const _ChartPoint({required this.x, required this.yHigh, required this.yLow, required this.day});
  final double x;
  final double yHigh;
  final double yLow;
  final DailyForecast day;
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.points, required this.palette});

  final List<_ChartPoint> points;
  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // range band (between high and low lines)
    final band = Path()..moveTo(points.first.x, points.first.yHigh);
    for (final p in points) {
      band.lineTo(p.x, p.yHigh);
    }
    for (final p in points.reversed) {
      band.lineTo(p.x, p.yLow);
    }
    band.close();
    canvas.drawPath(band, Paint()..color = palette.chartBand);

    _drawPolyline(canvas, [for (final p in points) Offset(p.x, p.yLow)], palette.chartLow);
    _drawPolyline(canvas, [for (final p in points) Offset(p.x, p.yHigh)], palette.chartHigh);

    _drawDots(canvas, [for (final p in points) Offset(p.x, p.yLow)], palette.chartLow);
    _drawDots(canvas, [for (final p in points) Offset(p.x, p.yHigh)], palette.chartHigh);
  }

  void _drawPolyline(Canvas canvas, List<Offset> pts, Color color) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawDots(Canvas canvas, List<Offset> pts, Color color) {
    final fill = Paint()..color = color;
    final border = Paint()
      ..color = palette.card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final p in pts) {
      canvas.drawCircle(p, 4.5, fill);
      canvas.drawCircle(p, 4.5, border);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => oldDelegate.points != points;
}
