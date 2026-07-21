import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/weather/models/air_quality.dart';

/// 현재 미세먼지(PM10)·초미세먼지(PM2.5) 수준을 등급색과 함께 보여주는 배지.
/// 강수확률 pill 바로 아래에 놓여 같은 pill 톤(pointBg)을 쓰되, 신호가 되는
/// 등급은 공식 4색(좋음 파랑·보통 초록·나쁨 주황·매우나쁨 빨강)으로 강조한다.
class AirQualityBadge extends StatelessWidget {
  const AirQualityBadge({super.key, required this.air});

  final AirQuality air;

  static const _gradeColors = {
    AirGrade.good: Color(0xFF2E7DF2),
    AirGrade.moderate: Color(0xFF1BA84A),
    AirGrade.bad: Color(0xFFF08C1D),
    AirGrade.veryBad: Color(0xFFE0433B),
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    final segments = <Widget>[
      if (air.pm10Grade != null) _segment('미세', air.pm10Grade!),
      if (air.pm25Grade != null) _segment('초미세', air.pm25Grade!),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      decoration: BoxDecoration(color: palette.pointBg, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('·', style: TextStyle(fontSize: 13, color: palette.textMuted)),
              ),
            segments[i],
          ],
        ],
      ),
    );
  }

  Widget _segment(String label, AirGrade grade) {
    final color = _gradeColors[grade]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Pretendard'),
            children: [
              TextSpan(text: '$label ', style: TextStyle(color: color.withValues(alpha: 0.75))),
              TextSpan(text: grade.label, style: TextStyle(color: color)),
            ],
          ),
        ),
      ],
    );
  }
}
