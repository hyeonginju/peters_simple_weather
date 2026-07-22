import '../../core/utils/kma_time_scheduler.dart';
import '../region/models/region.dart';
import 'forecast_disk_cache.dart';
import 'mappers/daily_forecast_merger.dart';
import 'mappers/daily_precipitation_total.dart';
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
  WeatherRepository({KmaApiClient? client, ForecastDiskCache? diskCache})
      : _client = client ?? KmaApiClient(),
        _diskCache = diskCache ?? ForecastDiskCache();

  final KmaApiClient _client;
  final ForecastDiskCache _diskCache;

  /// region.id별 결과 캐시. 기상청 관측·예보는 10분 내에 거의 바뀌지 않으므로
  /// 메인 화면 스와이프로 지역을 오갈 때마다 재요청하지 않도록 한다.
  static const _cacheTtl = Duration(minutes: 10);
  final Map<String, ({ForecastResult result, DateTime fetchedAt})> _cache = {};

  /// 캐시를 무시하고 강제로 새로 요청하고 싶을 때(재시도 버튼 등) 호출한다.
  void invalidate(Region region) => _cache.remove(region.id);

  /// 해당 지역 데이터를 실제로 서버에서 받아온 시각. 캐시 히트로 돌려준
  /// 경우에도 원래 fetch 시각을 가리킨다(= "마지막 업데이트" 시각). 성공/부분
  /// 성공만 캐시되므로 실패 후에는 null.
  DateTime? fetchedAtFor(Region region) => _cache[region.id]?.fetchedAt;

  /// 메모리 캐시가 TTL 안에 있어 [fetch]가 네트워크 없이 즉시 돌아오는 상태인지.
  bool isFresh(Region region, {DateTime? now}) {
    final cached = _cache[region.id];
    if (cached == null) return false;
    return (now ?? DateTime.now()).difference(cached.fetchedAt) < _cacheTtl;
  }

  /// 신선도와 무관하게 당장 그릴 수 있는 마지막 성공 결과(SWR의 stale 단계).
  /// 메모리 캐시가 비어 있으면(앱 프로세스 새로 시작) 디스크에서 복원해
  /// 메모리 캐시에 올린다 — fetchedAt도 원래 시각으로 복원되므로 TTL 판정과
  /// "마지막 업데이트" 라벨이 그대로 이어진다. 아무것도 없으면 null.
  Future<ForecastResult?> staleResult(Region region, {DateTime? now}) async {
    final cached = _cache[region.id];
    if (cached != null) return cached.result;

    final restored = await _diskCache.load(region.id, now ?? DateTime.now());
    if (restored == null) return null;
    _cache[region.id] = (result: restored.result, fetchedAt: restored.fetchedAt);
    return restored.result;
  }

  Future<ForecastResult> fetch(Region region, {DateTime? now}) async {
    final currentTime = now ?? DateTime.now();

    final cached = _cache[region.id];
    if (cached != null && currentTime.difference(cached.fetchedAt) < _cacheTtl) {
      return cached.result;
    }

    final hourlyResult = await _fetchHourly(region, currentTime);
    if (hourlyResult == null) {
      return const ForecastResult.failure('기상청 서버에서 데이터를 불러오지 못했습니다.');
    }

    final snapshot = await _buildSnapshot(region, currentTime, hourlyResult);

    final dailyResult = await _fetchDaily(region, currentTime, hourlyResult);

    final result = dailyResult == null
        ? ForecastResult.partialFailure(snapshot: snapshot, hourly: hourlyResult, daily: null)
        : ForecastResult.success(snapshot: snapshot, hourly: hourlyResult, daily: dailyResult);

    _cache[region.id] = (result: result, fetchedAt: currentTime);
    if (result is ForecastSuccess) {
      // 다음 앱 시작의 첫 화면용(SWR). 저장 실패는 save가 알아서 무시한다.
      await _diskCache.save(region.id, result, currentTime);
    }
    return result;
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
    // 대기질은 초단기실황과 독립적이라 먼저 걸어두고 마지막에 기다린다(비치명적).
    final airQualityFuture = _client.getAirQuality(province: region.province, name: region.name);
    final observed = await _fetchObservedPrecipitationToday(region);
    final precipitationTotal = observed.isFirstDay
        ? sumPrecipitationToday(hourly, now)
        : mergeTodayPrecipitationTotal(observed.accumulatedRn, hourly, now);
    final airQuality = await airQualityFuture;

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
      int? humidity;

      // getUltraSrtNcst has no SKY (cloud-cover) field — only an observed
      // PTY. Sky condition keeps coming from the short-term forecast hour.
      for (final item in items) {
        switch (item.category) {
          case 'T1H':
            temperature = double.tryParse(item.obsrValue);
          case 'PTY':
            precipitationType = precipitationTypeFromCode(item.obsrValue);
          case 'REH':
            humidity = int.tryParse(item.obsrValue);
        }
      }

      return WeatherSnapshot(
        temperature: temperature ?? fallback.temperature,
        sky: fallback.sky,
        precipitationType: precipitationType ?? fallback.precipitationType,
        precipitationAmount: fallback.precipitationAmount,
        precipitationProbability: fallback.precipitationProbability,
        todayPrecipitationTotal: precipitationTotal,
        humidity: humidity,
        airQuality: airQuality,
      );
    } catch (_) {
      return WeatherSnapshot(
        temperature: fallback.temperature,
        sky: fallback.sky,
        precipitationType: fallback.precipitationType,
        precipitationAmount: fallback.precipitationAmount,
        precipitationProbability: fallback.precipitationProbability,
        todayPrecipitationTotal: precipitationTotal,
        airQuality: airQuality,
      );
    }
  }

  /// 서버가 초단기실황 RN1로 누적해둔 "오늘 00시~마지막 관측 시간대까지" 실측
  /// 강수량. 조회 실패 시 isFirstDay(순수 예보 합산)로 폴백 — accumulatedRn=0으로
  /// 하이브리드 합산을 타면 지난 시간대가 통째로 빠져 과소 계산되므로, 실측을
  /// 아예 못 믿는 상황에서는 하루 전체를 예보값으로 채우는 쪽이 더 안전하다.
  Future<({double accumulatedRn, bool isFirstDay})> _fetchObservedPrecipitationToday(Region region) async {
    try {
      return await _client.getPrecipToday(nx: region.nx, ny: region.ny);
    } catch (_) {
      return (accumulatedRn: 0.0, isFirstDay: true);
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
      shortTermDaily = groupDailyFromHourly(hourly, now);
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
      // 동시 호출(Future.wait)은 KMA 게이트웨이의 동시/초당 요청 한도를 넘겨
      // 429를 유발하기 쉬워, 위젯 새로고침의 호출 버스트를 줄이도록 순차 호출한다.
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
