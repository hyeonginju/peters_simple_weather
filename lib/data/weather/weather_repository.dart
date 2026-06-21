import '../../core/utils/kma_time_scheduler.dart';
import '../region/models/region.dart';
import 'mappers/daily_forecast_merger.dart';
import 'mappers/mid_term_converter.dart';
import 'mappers/vilage_fcst_grouper.dart';
import 'mappers/weather_interpolator.dart';
import 'models/daily_forecast.dart';
import 'models/forecast_result.dart';
import 'models/hourly_forecast.dart';
import 'models/kma_forecast_item.dart';
import 'models/weather_snapshot.dart';
import '../kma/kma_api_client.dart';

class WeatherRepository {
  WeatherRepository({KmaApiClient? client}) : _client = client ?? KmaApiClient();

  final KmaApiClient _client;

  Future<ForecastResult> fetch(Region region, {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();

    final hourlyResult = await _fetchHourly(region, currentTime);
    if (hourlyResult == null) {
      return const ForecastResult.failure('기상청 서버에서 데이터를 불러오지 못했습니다.');
    }

    final snapshot = await _buildSnapshot(region, currentTime, hourlyResult);

    final dailyResult = await _fetchDaily(region, currentTime, hourlyResult);

    if (dailyResult == null) {
      return ForecastResult.partialFailure(snapshot: snapshot, hourly: hourlyResult, daily: null);
    }

    return ForecastResult.success(snapshot: snapshot, hourly: hourlyResult, daily: dailyResult);
  }

  Future<List<HourlyForecast>?> _fetchHourly(Region region, DateTime now) async {
    try {
      final base = KmaTimeScheduler.resolveVilageFcstBaseTime(now);
      final items = await _client.getVilageFcst(
        nx: region.nx,
        ny: region.ny,
        baseDate: base.baseDate,
        baseTime: base.baseTime,
      );
      final kmaItems = items
          .map((dto) => KmaForecastItem(
                category: dto.category,
                fcstDate: dto.fcstDate,
                fcstTime: dto.fcstTime,
                fcstValue: dto.fcstValue,
              ))
          .toList();
      final drafts = groupVilageFcstItems(kmaItems);
      final hourly = interpolateHourlyForecasts(drafts);
      return hourly.isEmpty ? null : hourly;
    } catch (_) {
      return null;
    }
  }

  Future<WeatherSnapshot> _buildSnapshot(
    Region region,
    DateTime now,
    List<HourlyForecast> hourly,
  ) async {
    final fallback = _closestHourTo(hourly, now);

    try {
      final base = KmaTimeScheduler.resolveUltraSrtNcstBaseTime(now);
      final items = await _client.getUltraSrtNcst(
        nx: region.nx,
        ny: region.ny,
        baseDate: base.baseDate,
        baseTime: base.baseTime,
      );

      double? temperature;
      PrecipitationType? precipitationType;

      // getUltraSrtNcst has no SKY (cloud-cover) field — only an observed
      // PTY. Sky condition keeps coming from the short-term forecast hour.
      for (final item in items) {
        switch (item.category) {
          case 'T1H':
            temperature = double.tryParse(item.obsrValue);
          case 'PTY':
            precipitationType = precipitationTypeFromCode(item.obsrValue);
        }
      }

      return WeatherSnapshot(
        temperature: temperature ?? fallback.temperature,
        sky: fallback.sky,
        precipitationType: precipitationType ?? fallback.precipitationType,
        precipitationAmount: fallback.precipitationAmount,
        precipitationProbability: fallback.precipitationProbability,
      );
    } catch (_) {
      return WeatherSnapshot(
        temperature: fallback.temperature,
        sky: fallback.sky,
        precipitationType: fallback.precipitationType,
        precipitationAmount: fallback.precipitationAmount,
        precipitationProbability: fallback.precipitationProbability,
      );
    }
  }

  HourlyForecast _closestHourTo(List<HourlyForecast> hourly, DateTime now) {
    return hourly.reduce((a, b) =>
        (a.time.difference(now).abs() <= b.time.difference(now).abs()) ? a : b);
  }

  Future<List<DailyForecast>?> _fetchDaily(
    Region region,
    DateTime now,
    List<HourlyForecast> hourly,
  ) async {
    final List<DailyForecast> shortTermDaily;
    try {
      shortTermDaily = groupDailyFromHourly(hourly);
    } catch (_) {
      return null;
    }

    final midLandCode = region.midLandCode;
    final midTaCode = region.midTaCode;
    if (midLandCode == null || midTaCode == null) {
      return shortTermDaily;
    }

    try {
      final tmFc = KmaTimeScheduler.resolveMidTermTmFc(now);
      final land = await _client.getMidLandFcst(regId: midLandCode, tmFc: tmFc);
      final ta = await _client.getMidTa(regId: midTaCode, tmFc: tmFc);

      final announcementDate = DateTime(
        int.parse(tmFc.substring(0, 4)),
        int.parse(tmFc.substring(4, 6)),
        int.parse(tmFc.substring(6, 8)),
      );
      final midTermDaily = convertMidTermForecast(land: land, ta: ta, announcementDate: announcementDate);

      return mergeDailyForecasts(shortTermDaily, midTermDaily);
    } catch (_) {
      // 중기예보(4~10일)만 죽었을 때는 이미 확보한 단기예보(1~3일)는 그대로
      // 보여준다 — graceful degradation.
      return shortTermDaily;
    }
  }
}
