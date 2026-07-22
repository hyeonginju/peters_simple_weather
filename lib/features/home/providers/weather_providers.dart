import 'dart:async';

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
///
/// stale-while-revalidate: 앱 프로세스가 새로 시작돼 메모리 캐시가 비어 있으면
/// 디스크에 남은 직전 성공 결과를 즉시 보여주고, 뒤에서 네트워크 갱신이 끝나면
/// 상태를 교체한다. 백엔드(Render 무료 플랜)가 유휴 후 잠들어 첫 요청에 20초+
/// 걸리는 콜드스타트를 사용자가 빈 화면으로 기다리지 않게 하기 위한 구조다.
@riverpod
class ForecastFor extends _$ForecastFor {
  @override
  Future<ForecastResult> build(Region region) async {
    final repo = ref.watch(weatherRepositoryProvider);
    if (repo.isFresh(region)) return repo.fetch(region);

    final stale = await repo.staleResult(region);
    if (stale == null) return repo.fetch(region);

    unawaited(Future.microtask(_revalidate));
    return stale;
  }

  /// 캐시를 보여준 상태에서 뒤에서 새 데이터를 받아 교체한다. 갱신이 실패하면
  /// 기존 화면을 그대로 둔다 — stale 데이터가 에러 화면보다 낫다.
  Future<void> _revalidate() async {
    var disposed = false;
    ref.onDispose(() => disposed = true);
    ref.read(regionRefreshingProvider(region).notifier).set(true);
    try {
      final fresh = await ref.read(weatherRepositoryProvider).fetch(region);
      if (disposed) return;
      if (fresh is! ForecastFailure) state = AsyncData(fresh);
    } finally {
      if (!disposed) ref.read(regionRefreshingProvider(region).notifier).set(false);
    }
  }

  /// 당겨서 새로고침·재시도 버튼 — 캐시를 무시하고 완료까지 기다렸다가 교체.
  /// 기존 화면은 교체 전까지 유지된다(skipLoadingOnRefresh).
  Future<void> forceRefresh() async {
    final repo = ref.read(weatherRepositoryProvider);
    repo.invalidate(region);
    state = await AsyncValue.guard(() => repo.fetch(region));
  }
}

/// 백그라운드 갱신(SWR revalidate) 진행 여부 — 홈 좌상단 '업데이트 중' 표시용.
@riverpod
class RegionRefreshing extends _$RegionRefreshing {
  @override
  bool build(Region region) => false;

  void set(bool value) => state = value;
}

/// 해당 지역 데이터를 마지막으로 서버에서 받아온 시각. forecastFor를 watch해
/// fetch가 끝나거나 강제 새로고침될 때마다 갱신된다(성공 전/실패 시 null).
@riverpod
DateTime? regionLastUpdated(Ref ref, Region region) {
  ref.watch(forecastForProvider(region));
  return ref.watch(weatherRepositoryProvider).fetchedAtFor(region);
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
