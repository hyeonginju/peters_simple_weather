import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/weather_icon_mapper.dart';
import '../../../core/widgets/weather_icon.dart';
import '../../../data/weather/models/daily_forecast.dart';
import '../../../data/weather/models/kma_forecast_item.dart';

/// 기온 추세 그래프 아래 — 오늘을 뺀 나머지 날들의 오전/오후 강수확률과 하루 총
/// 강수량을 표로 보여준다. 강수량은 단기예보가 커버하는 앞쪽 며칠(D+1~3)만 값이
/// 있고 중기예보 구간은 '–'(기상청 중기예보가 강수량 수치를 주지 않음).
class WeeklyPrecipSection extends StatelessWidget {
  const WeeklyPrecipSection({super.key, required this.daily, required this.today});

  final List<DailyForecast> daily;
  final DateTime today;

  static const _dayColWidth = 46.0;
  static const _iconColWidth = 30.0;
  static const _precipColWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final t = DateTime(today.year, today.month, today.day);
    final days = daily
        .where((d) => DateTime(d.date.year, d.date.month, d.date.day).isAfter(t))
        .toList();
    if (days.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 6),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('강수 예보', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary)),
          ),
          _header(palette),
          for (var i = 0; i < days.length; i++)
            _PrecipRow(day: days[i], today: today, showDivider: i < days.length - 1),
        ],
      ),
    );
  }

  Widget _header(AppPalette palette) {
    TextStyle style() => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.textMuted);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          const SizedBox(width: _dayColWidth),
          const SizedBox(width: _iconColWidth),
          Expanded(child: Text('오전', textAlign: TextAlign.center, style: style())),
          Expanded(child: Text('오후', textAlign: TextAlign.center, style: style())),
          SizedBox(
            width: _precipColWidth,
            child: Text('강수량', textAlign: TextAlign.right, style: style()),
          ),
        ],
      ),
    );
  }
}

class _PrecipRow extends StatelessWidget {
  const _PrecipRow({required this.day, required this.today, required this.showDivider});

  final DailyForecast day;
  final DateTime today;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sky = day.sky ?? SkyCondition.clear;
    final pty = day.precipitationType ?? PrecipitationType.none;
    final label = formatWeeklyDayLabel(day.date, today: today).split(' ').first;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: showDivider
          ? BoxDecoration(border: Border(bottom: BorderSide(color: palette.divider)))
          : null,
      child: Row(
        children: [
          SizedBox(
            width: WeeklyPrecipSection._dayColWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                const SizedBox(height: 1),
                Text('${day.date.month}/${day.date.day}', style: TextStyle(fontSize: 10.5, color: palette.textMuted)),
              ],
            ),
          ),
          SizedBox(
            width: WeeklyPrecipSection._iconColWidth,
            child: Center(child: WeatherIcon(type: weatherIconTypeFor(sky, pty), size: 24)),
          ),
          Expanded(child: _popText(day.amPop, palette)),
          Expanded(child: _popText(day.pmPop, palette)),
          SizedBox(
            width: WeeklyPrecipSection._precipColWidth,
            child: Text(
              day.precipTotalMm == null ? '–' : '${day.precipTotalMm!.toStringAsFixed(1)}mm',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: day.precipTotalMm == null ? palette.textFaint : palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popText(int? pop, AppPalette palette) {
    return Text(
      pop == null ? '–' : '$pop%',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: pop == null ? palette.textFaint : palette.rain,
      ),
    );
  }
}
