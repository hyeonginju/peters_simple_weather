import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/alert/alert_repository.dart';
import '../../../data/alert/models/weather_alert.dart';

part 'alert_providers.g.dart';

@Riverpod(keepAlive: true)
AlertRepository alertRepository(Ref ref) => AlertRepository();

/// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.
///
/// stale-while-revalidate: 직전에 성공한 통보문(메모리/디스크)이 있으면 즉시
/// 보여주고 뒤에서 갱신한다. 특보 조회도 Render 프록시를 거치므로, 서버가
/// 유휴 후 잠들어 있으면(콜드스타트 20초+) 캐시 없이는 스피너만 보게 된다.
@riverpod
class AlertStatus extends _$AlertStatus {
  @override
  Future<WeatherAlertStatus> build(String stnId) async {
    final repo = ref.watch(alertRepositoryProvider);
    if (repo.isFresh(stnId)) return repo.fetchByStnId(stnId);

    final stale = await repo.staleResult(stnId);
    if (stale == null) return repo.fetchByStnId(stnId);

    unawaited(Future.microtask(_revalidate));
    return stale;
  }

  /// 캐시를 보여준 상태에서 뒤에서 새 통보문을 받아 교체한다. 갱신이 실패하면
  /// 기존 화면을 그대로 둔다 — stale 통보문이 에러 화면보다 낫다.
  Future<void> _revalidate() async {
    var disposed = false;
    ref.onDispose(() => disposed = true);
    ref.read(alertRefreshingProvider(stnId).notifier).set(true);
    try {
      final fresh = await ref.read(alertRepositoryProvider).fetchByStnId(stnId);
      if (!disposed) state = AsyncData(fresh);
    } catch (_) {
      // stale 유지.
    } finally {
      if (!disposed) ref.read(alertRefreshingProvider(stnId).notifier).set(false);
    }
  }

  /// 에러 화면의 다시 시도 — 캐시를 무시하고 완료까지 기다렸다가 교체.
  Future<void> forceRefresh() async {
    final repo = ref.read(alertRepositoryProvider);
    repo.invalidate(stnId);
    state = await AsyncValue.guard(() => repo.fetchByStnId(stnId));
  }
}

/// 백그라운드 갱신(SWR revalidate) 진행 여부 — 특보 화면 '업데이트 중' 표시용.
///
/// keepAlive — 갱신이 시작되는 시점은 화면(리스너)이 아직 붙기 전이다.
/// autoDispose면 리스너 없는 set(true)가 인스턴스째 버려져, 그 뒤에 구독을
/// 시작한 라벨은 새 인스턴스의 false만 보게 돼 인디케이터가 아예 안 뜬다
/// (홈 RegionRefreshing에서 실기기로 확인한 동일 함정).
@Riverpod(keepAlive: true)
class AlertRefreshing extends _$AlertRefreshing {
  @override
  bool build(String stnId) => false;

  void set(bool value) => state = value;
}
