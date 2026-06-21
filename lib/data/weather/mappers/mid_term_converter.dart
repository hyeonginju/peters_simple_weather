import '../../kma/dto/mid_land_fcst_dto.dart';
import '../../kma/dto/mid_ta_dto.dart';
import '../models/daily_forecast.dart';
import '../models/kma_forecast_item.dart';

/// getMidLandFcst's `wf` field is a free-text Korean weather description
/// (e.g. "비", "구름많음"), not a coded value — infer our icon enums from it.
PrecipitationType _precipitationTypeFromWf(String? wf) {
  if (wf == null) return PrecipitationType.none;
  final hasRain = wf.contains('비');
  final hasSnow = wf.contains('눈');
  if (hasRain && hasSnow) return PrecipitationType.rainAndSnow;
  if (hasSnow) return PrecipitationType.snow;
  if (hasRain) return PrecipitationType.rain;
  return PrecipitationType.none;
}

SkyCondition _skyFromWf(String? wf) {
  if (wf == null) return SkyCondition.partlyCloudy;
  if (wf.contains('흐림')) return SkyCondition.cloudy;
  if (wf.contains('구름많음')) return SkyCondition.partlyCloudy;
  if (wf.contains('맑음')) return SkyCondition.clear;
  return SkyCondition.partlyCloudy;
}

/// Converts the raw day-indexed mid-term DTOs (오늘+3 ~ 오늘+10, relative to
/// the announcement date) into day 4-10 entries — day 3 is skipped since the
/// short-term forecast already covers it.
List<MidTermDayForecast> convertMidTermForecast({
  required MidLandFcstDto land,
  required MidTaDto ta,
  required DateTime announcementDate,
}) {
  final result = <MidTermDayForecast>[];

  for (var day = 4; day <= 10; day++) {
    final minTemp = _taMinForDay(ta, day);
    final maxTemp = _taMaxForDay(ta, day);
    if (minTemp == null || maxTemp == null) {
      continue;
    }

    final amPop = _rnStAmForDay(land, day);
    final pmPop = _rnStPmForDay(land, day);
    final wf = _wfForDay(land, day);

    result.add(MidTermDayForecast(
      date: DateTime(announcementDate.year, announcementDate.month, announcementDate.day)
          .add(Duration(days: day)),
      amPopPercent: amPop ?? 0,
      pmPopPercent: pmPop ?? 0,
      minTemp: minTemp,
      maxTemp: maxTemp,
      sky: _skyFromWf(wf),
      precipitationType: _precipitationTypeFromWf(wf),
    ));
  }

  return result;
}

double? _taMinForDay(MidTaDto ta, int day) {
  return switch (day) {
    4 => ta.taMin4,
    5 => ta.taMin5,
    6 => ta.taMin6,
    7 => ta.taMin7,
    8 => ta.taMin8,
    9 => ta.taMin9,
    10 => ta.taMin10,
    _ => null,
  };
}

double? _taMaxForDay(MidTaDto ta, int day) {
  return switch (day) {
    4 => ta.taMax4,
    5 => ta.taMax5,
    6 => ta.taMax6,
    7 => ta.taMax7,
    8 => ta.taMax8,
    9 => ta.taMax9,
    10 => ta.taMax10,
    _ => null,
  };
}

/// Days 8-10 only have a single daily 강수확률 (no AM/PM split) — used for
/// both the AM and PM slot.
int? _rnStAmForDay(MidLandFcstDto land, int day) {
  return switch (day) {
    4 => land.rnSt4Am,
    5 => land.rnSt5Am,
    6 => land.rnSt6Am,
    7 => land.rnSt7Am,
    8 => land.rnSt8,
    9 => land.rnSt9,
    10 => land.rnSt10,
    _ => null,
  };
}

int? _rnStPmForDay(MidLandFcstDto land, int day) {
  return switch (day) {
    4 => land.rnSt4Pm,
    5 => land.rnSt5Pm,
    6 => land.rnSt6Pm,
    7 => land.rnSt7Pm,
    8 => land.rnSt8,
    9 => land.rnSt9,
    10 => land.rnSt10,
    _ => null,
  };
}

/// Prefers the AM text (days 3-7); days 8-10 only have a single daily value.
String? _wfForDay(MidLandFcstDto land, int day) {
  return switch (day) {
    4 => land.wf4Am ?? land.wf4Pm,
    5 => land.wf5Am ?? land.wf5Pm,
    6 => land.wf6Am ?? land.wf6Pm,
    7 => land.wf7Am ?? land.wf7Pm,
    8 => land.wf8,
    9 => land.wf9,
    10 => land.wf10,
    _ => null,
  };
}
