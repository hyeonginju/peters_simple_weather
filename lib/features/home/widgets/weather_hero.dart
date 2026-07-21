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
    required this.now,
    required this.todayPrecipitationTotal,
    this.comparison,
  });

  final WeatherSnapshot snapshot;
  final DailyForecast? today;
  final DateTime now;
  final double todayPrecipitationTotal;

  /// Optional "어제보다 1° 높아요" line. Omitted when no comparison data
  /// is available (we don't yet fetch yesterday's reading).
  final String? comparison;

  /// 지금이 오전(0~11시)이면 오늘 오전 강수확률, 오후(12~23시)면 오후 강수확률을
  /// 쓴다("가장 가까운 시각" 값 대신 현재 시간대 대표값). 단기예보는 지난 시간대를
  /// 돌려주지 않아 해당 반나절 값이 없을 수 있는데, 그때는 오늘 대표값(최댓값)으로
  /// 폴백하고, 오늘 일자 데이터 자체가 없으면 현재 시각 슬롯 값으로 폴백한다.
  int _currentHalfPop() {
    if (today == null) return snapshot.precipitationProbability;
    final half = now.hour < 12 ? today!.amPop : today!.pmPop;
    return half ?? today!.popPercent;
  }

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
            '강수확률 ${_currentHalfPop()}%'
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
