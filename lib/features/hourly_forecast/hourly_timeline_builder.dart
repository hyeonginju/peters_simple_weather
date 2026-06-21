import '../../core/utils/date_formatter.dart';
import '../../data/weather/models/hourly_forecast.dart';
import '../../data/weather/models/weather_snapshot.dart';
import 'hourly_timeline_entry.dart';

/// Builds the "지금 → 16시 → 17시 → ..." timeline: the current snapshot as
/// the first "지금" entry, followed by every forecast hour strictly after
/// the current time (기획서 4.1).
List<HourlyTimelineEntry> buildHourlyTimeline({
  required WeatherSnapshot snapshot,
  required List<HourlyForecast> hourly,
  required DateTime now,
}) {
  final upcoming = hourly.where((h) => h.time.isAfter(now)).toList()
    ..sort((a, b) => a.time.compareTo(b.time));

  return [
    HourlyTimelineEntry(
      label: '지금',
      time: now,
      temperature: snapshot.temperature,
      sky: snapshot.sky,
      precipitationType: snapshot.precipitationType,
      precipitationAmount: snapshot.precipitationAmount,
      precipitationProbability: snapshot.precipitationProbability,
    ),
    for (final hour in upcoming)
      HourlyTimelineEntry(
        label: formatHourLabel(hour.time),
        time: hour.time,
        temperature: hour.temperature,
        sky: hour.sky,
        precipitationType: hour.precipitationType,
        precipitationAmount: hour.precipitationAmount,
        precipitationProbability: hour.precipitationProbability,
      ),
  ];
}

/// 스크롤된 시간별 타임라인에서 중앙에 온 셀의 날짜 라벨. 같은 날이면
/// "오늘 20일", 다음날 "내일 21일", 그 다음날 "모레 22일", 그 외 "6월 23일".
String hourlyDateLabel(DateTime time, {required DateTime today}) {
  final d0 = DateTime(today.year, today.month, today.day);
  final d1 = DateTime(time.year, time.month, time.day);
  final diff = d1.difference(d0).inDays;
  final word = switch (diff) {
    0 => '오늘',
    1 => '내일',
    2 => '모레',
    _ => '${time.month}월',
  };
  return '$word ${time.day}일';
}
