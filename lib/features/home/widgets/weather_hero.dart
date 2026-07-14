import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/weather_icon_mapper.dart';
import '../../../core/widgets/weather_icon.dart';
import '../../../data/weather/models/daily_forecast.dart';
import '../../../data/weather/models/weather_snapshot.dart';

class WeatherHero extends StatelessWidget {
  const WeatherHero({
    super.key,
    required this.snapshot,
    required this.today,
    required this.todayPrecipitationTotal,
    this.comparison,
  });

  final WeatherSnapshot snapshot;
  final DailyForecast? today;
  final double todayPrecipitationTotal;

  /// Optional "어제보다 1° 높아요" line. Omitted when no comparison data
  /// is available (we don't yet fetch yesterday's reading).
  final String? comparison;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // 오늘 1mm 이상 내렸다면(과거 실측 + 남은 시간 예보 합산 기준) 지금 비가
    // 그쳐 있어도 계속 "오늘 총 강수량"을 보여준다 — 현재 강수 여부만 보면
    // 하루 총량이라는 문구와 맞지 않는 순간이 생기기 때문.
    final hasPrecipitatedToday = snapshot.todayPrecipitationTotal >= 1.0;

    return Column(
      children: [
        WeatherIcon(type: weatherIconTypeFor(snapshot.sky, snapshot.precipitationType), size: 104),
        const SizedBox(height: 6),
        Text(
          '${snapshot.temperature.round()}°',
          style: TextStyle(
            fontSize: 76,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: -3,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              weatherConditionLabel(snapshot.sky, snapshot.precipitationType),
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: palette.textPrimary),
            ),
            if (comparison != null) ...[
              const SizedBox(width: 8),
              Text('·', style: TextStyle(fontSize: 14, color: palette.textMuted)),
              const SizedBox(width: 8),
              Text(
                comparison!,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: palette.textSecondary),
              ),
            ],
          ],
        ),
        if (today != null || snapshot.humidity != null) ...[
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (today != null) ...[
                _MinMax(label: '최저', value: '${today!.minTemp.round()}°', palette: palette),
                const SizedBox(width: 14),
                _MinMax(label: '최고', value: '${today!.maxTemp.round()}°', palette: palette),
              ],
              if (snapshot.humidity != null) ...[
                if (today != null) const SizedBox(width: 14),
                _MinMax(label: '습도', value: '${snapshot.humidity}%', palette: palette),
              ],
            ],
          ),
        ],
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          decoration: BoxDecoration(color: palette.pointBg, borderRadius: BorderRadius.circular(99)),
          child: Text(
            hasPrecipitatedToday
                ? '오늘 총 강수량 ${todayPrecipitationTotal.toStringAsFixed(1)}mm'
                : '오늘 강수확률 ${today?.popPercent ?? snapshot.precipitationProbability}%',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.pointText),
          ),
        ),
      ],
    );
  }
}

class _MinMax extends StatelessWidget {
  const _MinMax({required this.label, required this.value, required this.palette});

  final String label;
  final String value;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: palette.textMuted, fontFamily: 'Pretendard'),
        children: [
          TextSpan(text: '$label '),
          TextSpan(
            text: value,
            style: TextStyle(fontWeight: FontWeight.w700, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
