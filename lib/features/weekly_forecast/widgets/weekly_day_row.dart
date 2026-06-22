import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/weather_icon_mapper.dart';
import '../../../core/widgets/weather_icon.dart';
import '../../../data/weather/models/daily_forecast.dart';
import '../../../data/weather/models/kma_forecast_item.dart';
import 'weekly_sparkline.dart';

class WeeklyDayRow extends StatelessWidget {
  const WeeklyDayRow({
    super.key,
    required this.day,
    required this.today,
    required this.weekMin,
    required this.weekMax,
    this.showDivider = true,
  });

  final DailyForecast day;
  final DateTime today;
  final double weekMin;
  final double weekMax;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sky = day.sky ?? SkyCondition.clear;
    final pty = day.precipitationType ?? PrecipitationType.none;
    final label = formatWeeklyDayLabel(day.date, today: today).split(' ').first;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: showDivider
          ? BoxDecoration(border: Border(bottom: BorderSide(color: palette.divider)))
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                const SizedBox(height: 1),
                Text(
                  '${day.date.month}/${day.date.day}',
                  style: TextStyle(fontSize: 10.5, color: palette.textMuted),
                ),
              ],
            ),
          ),
          WeatherIcon(type: weatherIconTypeFor(sky, pty), size: 24),
          SizedBox(
            width: 42,
            child: Text(
              '${day.popPercent}%',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: palette.rain),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: WeeklySparkline(
              dayMin: day.minTemp,
              dayMax: day.maxTemp,
              weekMin: weekMin,
              weekMax: weekMax,
              color: palette.rain,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 30,
            child: Text(
              '${day.minTemp.round()}°',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, color: palette.textMuted),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              '${day.maxTemp.round()}°',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
