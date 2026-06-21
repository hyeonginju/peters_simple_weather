import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/weather_icon_mapper.dart';
import '../../../core/widgets/weather_icon.dart';
import '../../../data/weather/models/kma_forecast_item.dart';
import '../hourly_timeline_entry.dart';

const double kHourCellWidth = 60;
const double kHourTimelinePadding = 14;

class HourlyTimeline extends StatelessWidget {
  const HourlyTimeline({super.key, required this.entries, this.controller});

  final List<HourlyTimelineEntry> entries;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return ListView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: kHourTimelinePadding),
      physics: const BouncingScrollPhysics(),
      itemExtent: kHourCellWidth,
      itemCount: entries.length,
      itemBuilder: (context, i) => _HourCell(entry: entries[i], palette: palette),
    );
  }
}

class _HourCell extends StatelessWidget {
  const _HourCell({required this.entry, required this.palette});

  final HourlyTimelineEntry entry;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final isPrecipitating = entry.precipitationType != PrecipitationType.none;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            entry.label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: palette.textSecondary),
          ),
          const SizedBox(height: 8),
          WeatherIcon(type: weatherIconTypeFor(entry.sky, entry.precipitationType), size: 34),
          const SizedBox(height: 8),
          // Fixed-height slot keeps every cell the same height whether or not
          // it shows a precipitation amount (otherwise rain cells overflow).
          SizedBox(
            height: 15,
            child: isPrecipitating
                ? Text(
                    '${entry.precipitationAmount.toStringAsFixed(1)}㎜',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: palette.rain),
                  )
                : null,
          ),
          const SizedBox(height: 2),
          Text(
            '${entry.precipitationProbability}%',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.temperature.round()}°',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: palette.textPrimary),
          ),
        ],
      ),
    );
  }
}
