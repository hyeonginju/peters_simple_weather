import 'package:flutter/material.dart';

/// 주간 리스트 각 행의 일교차 스파크라인. 모든 행이 같은 주간 기온 스케일
/// (weekMin~weekMax)을 공유하므로, 선의 상하 위치는 절대 기온(따뜻할수록
/// 위), 진폭은 그날의 일교차(최저~최고)를 나타낸다. 최저=최고면 평평한 선.
class WeeklySparkline extends StatelessWidget {
  const WeeklySparkline({
    super.key,
    required this.dayMin,
    required this.dayMax,
    required this.weekMin,
    required this.weekMax,
    required this.color,
  });

  final double dayMin;
  final double dayMax;
  final double weekMin;
  final double weekMax;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 30),
      painter: _SparklinePainter(
        dayMin: dayMin,
        dayMax: dayMax,
        weekMin: weekMin,
        weekMax: weekMax,
        color: color,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.dayMin,
    required this.dayMax,
    required this.weekMin,
    required this.weekMax,
    required this.color,
  });

  final double dayMin;
  final double dayMax;
  final double weekMin;
  final double weekMax;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const pad = 5.0; // top/bottom breathing room
    final span = (weekMax - weekMin).abs() < 0.5 ? 1.0 : (weekMax - weekMin);
    double y(double t) => pad + (1 - (t - weekMin) / span) * (size.height - 2 * pad);

    final yLow = y(dayMin);
    final yHigh = y(dayMax);

    final path = Path()..moveTo(0, yLow);
    // Smooth hill: rise from the day's low (edges) to its high (centre).
    path.cubicTo(size.width * 0.25, yLow, size.width * 0.32, yHigh, size.width * 0.5, yHigh);
    path.cubicTo(size.width * 0.68, yHigh, size.width * 0.75, yLow, size.width, yLow);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.dayMin != dayMin || old.dayMax != dayMax || old.weekMin != weekMin || old.weekMax != weekMax || old.color != color;
}
