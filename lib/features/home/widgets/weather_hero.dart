import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/weather_icon_mapper.dart';
import '../../../core/widgets/weather_icon.dart';
import '../../../data/weather/models/daily_forecast.dart';
import '../../../data/weather/models/weather_snapshot.dart';
import 'air_quality_badge.dart';

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
            '강수확률 ${today?.popPercent ?? snapshot.precipitationProbability}%'
                ' · 총 강수량 ${todayPrecipitationTotal.toStringAsFixed(1)}mm',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.pointText),
          ),
        ),
        if (snapshot.airQuality?.hasAny ?? false) ...[
          const SizedBox(height: 9),
          AirQualityBadge(air: snapshot.airQuality!),
        ],
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
