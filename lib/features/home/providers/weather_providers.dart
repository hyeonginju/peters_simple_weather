import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/region/models/region.dart';
import '../../../data/weather/models/forecast_result.dart';
import '../../../data/weather/weather_repository.dart';
import '../../region_picker/providers/region_providers.dart';

part 'weather_providers.g.dart';

/// keepAlive — WeatherRepository는 region.id별로 10분 TTL 캐시를 들고 있다.
/// autoDispose였다면 지역 전환마다 forecastFor가 폐기되며 이 provider도
/// 함께 재생성되어 캐시가 매번 날아간다.
@Riverpod(keepAlive: true)
WeatherRepository weatherRepository(Ref ref) => WeatherRepository();

/// Keyed by region — only the active region's screen watches this, so
/// Riverpod's autoDispose semantics naturally implement the spec's
/// "진입 시점에만 API 요청" lazy-fetch requirement: switching away from a
/// region disposes its provider instance instead of polling in the background.
/// 실제 네트워크 요청 여부는 WeatherRepository의 10분 TTL 캐시가 결정한다.
@riverpod
Future<ForecastResult> forecastFor(Ref ref, Region region) async {
  return ref.watch(weatherRepositoryProvider).fetch(region);
}

@riverpod
class ActiveRegionIndex extends _$ActiveRegionIndex {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

@riverpod
Future<Region?> activeRegion(Ref ref) async {
  final regions = await ref.watch(savedRegionsProvider.future);
  if (regions.isEmpty) {
    return null;
  }
  final index = ref.watch(activeRegionIndexProvider).clamp(0, regions.length - 1);
  return regions[index];
}
