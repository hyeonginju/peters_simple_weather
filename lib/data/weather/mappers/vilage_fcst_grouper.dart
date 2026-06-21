import '../models/kma_forecast_item.dart';
import '../../../core/utils/pcp_parser.dart';

/// Groups KMA's flat, category-per-row response (TMP/SKY/PTY/POP/PCP each
/// as a separate item for the same fcstDate+fcstTime) into one draft per
/// hourly slot. Unknown categories are ignored.
List<HourlyForecastDraft> groupVilageFcstItems(List<KmaForecastItem> items) {
  final byTime = <DateTime, HourlyForecastDraft>{};

  for (final item in items) {
    final time = _parseFcstDateTime(item.fcstDate, item.fcstTime);
    final draft = byTime.putIfAbsent(time, () => HourlyForecastDraft(time: time));

    switch (item.category) {
      case 'TMP':
        draft.temperature = double.tryParse(item.fcstValue);
      case 'SKY':
        draft.sky = skyConditionFromCode(item.fcstValue);
      case 'PTY':
        draft.precipitationType = precipitationTypeFromCode(item.fcstValue);
      case 'POP':
        draft.precipitationProbability = int.tryParse(item.fcstValue);
      case 'PCP':
        draft.precipitationAmount = parsePrecipitationAmount(item.fcstValue);
    }
  }

  final drafts = byTime.values.toList()..sort((a, b) => a.time.compareTo(b.time));
  return drafts;
}

DateTime _parseFcstDateTime(String fcstDate, String fcstTime) {
  final year = int.parse(fcstDate.substring(0, 4));
  final month = int.parse(fcstDate.substring(4, 6));
  final day = int.parse(fcstDate.substring(6, 8));
  final hour = int.parse(fcstTime.substring(0, 2));
  return DateTime(year, month, day, hour);
}
