// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alert_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(alertRepository)
final alertRepositoryProvider = AlertRepositoryProvider._();

final class AlertRepositoryProvider
    extends
        $FunctionalProvider<AlertRepository, AlertRepository, AlertRepository>
    with $Provider<AlertRepository> {
  AlertRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alertRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alertRepositoryHash();

  @$internal
  @override
  $ProviderElement<AlertRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlertRepository create(Ref ref) {
    return alertRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlertRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlertRepository>(value),
    );
  }
}

String _$alertRepositoryHash() => r'40d9509d9ecb108403dc414e6814b1524ea34ca9';

/// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.
///
/// stale-while-revalidate: 직전에 성공한 통보문(메모리/디스크)이 있으면 즉시
/// 보여주고 뒤에서 갱신한다. 특보 조회도 Render 프록시를 거치므로, 서버가
/// 유휴 후 잠들어 있으면(콜드스타트 20초+) 캐시 없이는 스피너만 보게 된다.

@ProviderFor(AlertStatus)
final alertStatusProvider = AlertStatusFamily._();

/// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.
///
/// stale-while-revalidate: 직전에 성공한 통보문(메모리/디스크)이 있으면 즉시
/// 보여주고 뒤에서 갱신한다. 특보 조회도 Render 프록시를 거치므로, 서버가
/// 유휴 후 잠들어 있으면(콜드스타트 20초+) 캐시 없이는 스피너만 보게 된다.
final class AlertStatusProvider
    extends $AsyncNotifierProvider<AlertStatus, WeatherAlertStatus> {
  /// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.
  ///
  /// stale-while-revalidate: 직전에 성공한 통보문(메모리/디스크)이 있으면 즉시
  /// 보여주고 뒤에서 갱신한다. 특보 조회도 Render 프록시를 거치므로, 서버가
  /// 유휴 후 잠들어 있으면(콜드스타트 20초+) 캐시 없이는 스피너만 보게 된다.
  AlertStatusProvider._({
    required AlertStatusFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'alertStatusProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$alertStatusHash();

  @override
  String toString() {
    return r'alertStatusProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AlertStatus create() => AlertStatus();

  @override
  bool operator ==(Object other) {
    return other is AlertStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$alertStatusHash() => r'6d80ce225ab6f3a9718aaed8d590adf0dd40cfd7';

/// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.
///
/// stale-while-revalidate: 직전에 성공한 통보문(메모리/디스크)이 있으면 즉시
/// 보여주고 뒤에서 갱신한다. 특보 조회도 Render 프록시를 거치므로, 서버가
/// 유휴 후 잠들어 있으면(콜드스타트 20초+) 캐시 없이는 스피너만 보게 된다.

final class AlertStatusFamily extends $Family
    with
        $ClassFamilyOverride<
          AlertStatus,
          AsyncValue<WeatherAlertStatus>,
          WeatherAlertStatus,
          FutureOr<WeatherAlertStatus>,
          String
        > {
  AlertStatusFamily._()
    : super(
        retry: null,
        name: r'alertStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.
  ///
  /// stale-while-revalidate: 직전에 성공한 통보문(메모리/디스크)이 있으면 즉시
  /// 보여주고 뒤에서 갱신한다. 특보 조회도 Render 프록시를 거치므로, 서버가
  /// 유휴 후 잠들어 있으면(콜드스타트 20초+) 캐시 없이는 스피너만 보게 된다.

  AlertStatusProvider call(String stnId) =>
      AlertStatusProvider._(argument: stnId, from: this);

  @override
  String toString() => r'alertStatusProvider';
}

/// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.
///
/// stale-while-revalidate: 직전에 성공한 통보문(메모리/디스크)이 있으면 즉시
/// 보여주고 뒤에서 갱신한다. 특보 조회도 Render 프록시를 거치므로, 서버가
/// 유휴 후 잠들어 있으면(콜드스타트 20초+) 캐시 없이는 스피너만 보게 된다.

abstract class _$AlertStatus extends $AsyncNotifier<WeatherAlertStatus> {
  late final _$args = ref.$arg as String;
  String get stnId => _$args;

  FutureOr<WeatherAlertStatus> build(String stnId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<WeatherAlertStatus>, WeatherAlertStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WeatherAlertStatus>, WeatherAlertStatus>,
              AsyncValue<WeatherAlertStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// 백그라운드 갱신(SWR revalidate) 진행 여부 — 특보 화면 '업데이트 중' 표시용.
///
/// keepAlive — 갱신이 시작되는 시점은 화면(리스너)이 아직 붙기 전이다.
/// autoDispose면 리스너 없는 set(true)가 인스턴스째 버려져, 그 뒤에 구독을
/// 시작한 라벨은 새 인스턴스의 false만 보게 돼 인디케이터가 아예 안 뜬다
/// (홈 RegionRefreshing에서 실기기로 확인한 동일 함정).

@ProviderFor(AlertRefreshing)
final alertRefreshingProvider = AlertRefreshingFamily._();

/// 백그라운드 갱신(SWR revalidate) 진행 여부 — 특보 화면 '업데이트 중' 표시용.
///
/// keepAlive — 갱신이 시작되는 시점은 화면(리스너)이 아직 붙기 전이다.
/// autoDispose면 리스너 없는 set(true)가 인스턴스째 버려져, 그 뒤에 구독을
/// 시작한 라벨은 새 인스턴스의 false만 보게 돼 인디케이터가 아예 안 뜬다
/// (홈 RegionRefreshing에서 실기기로 확인한 동일 함정).
final class AlertRefreshingProvider
    extends $NotifierProvider<AlertRefreshing, bool> {
  /// 백그라운드 갱신(SWR revalidate) 진행 여부 — 특보 화면 '업데이트 중' 표시용.
  ///
  /// keepAlive — 갱신이 시작되는 시점은 화면(리스너)이 아직 붙기 전이다.
  /// autoDispose면 리스너 없는 set(true)가 인스턴스째 버려져, 그 뒤에 구독을
  /// 시작한 라벨은 새 인스턴스의 false만 보게 돼 인디케이터가 아예 안 뜬다
  /// (홈 RegionRefreshing에서 실기기로 확인한 동일 함정).
  AlertRefreshingProvider._({
    required AlertRefreshingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'alertRefreshingProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$alertRefreshingHash();

  @override
  String toString() {
    return r'alertRefreshingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AlertRefreshing create() => AlertRefreshing();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AlertRefreshingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$alertRefreshingHash() => r'07ef79d4d28e0b123b4182c67ac8d72c24b756f9';

/// 백그라운드 갱신(SWR revalidate) 진행 여부 — 특보 화면 '업데이트 중' 표시용.
///
/// keepAlive — 갱신이 시작되는 시점은 화면(리스너)이 아직 붙기 전이다.
/// autoDispose면 리스너 없는 set(true)가 인스턴스째 버려져, 그 뒤에 구독을
/// 시작한 라벨은 새 인스턴스의 false만 보게 돼 인디케이터가 아예 안 뜬다
/// (홈 RegionRefreshing에서 실기기로 확인한 동일 함정).

final class AlertRefreshingFamily extends $Family
    with $ClassFamilyOverride<AlertRefreshing, bool, bool, bool, String> {
  AlertRefreshingFamily._()
    : super(
        retry: null,
        name: r'alertRefreshingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 백그라운드 갱신(SWR revalidate) 진행 여부 — 특보 화면 '업데이트 중' 표시용.
  ///
  /// keepAlive — 갱신이 시작되는 시점은 화면(리스너)이 아직 붙기 전이다.
  /// autoDispose면 리스너 없는 set(true)가 인스턴스째 버려져, 그 뒤에 구독을
  /// 시작한 라벨은 새 인스턴스의 false만 보게 돼 인디케이터가 아예 안 뜬다
  /// (홈 RegionRefreshing에서 실기기로 확인한 동일 함정).

  AlertRefreshingProvider call(String stnId) =>
      AlertRefreshingProvider._(argument: stnId, from: this);

  @override
  String toString() => r'alertRefreshingProvider';
}

/// 백그라운드 갱신(SWR revalidate) 진행 여부 — 특보 화면 '업데이트 중' 표시용.
///
/// keepAlive — 갱신이 시작되는 시점은 화면(리스너)이 아직 붙기 전이다.
/// autoDispose면 리스너 없는 set(true)가 인스턴스째 버려져, 그 뒤에 구독을
/// 시작한 라벨은 새 인스턴스의 false만 보게 돼 인디케이터가 아예 안 뜬다
/// (홈 RegionRefreshing에서 실기기로 확인한 동일 함정).

abstract class _$AlertRefreshing extends $Notifier<bool> {
  late final _$args = ref.$arg as String;
  String get stnId => _$args;

  bool build(String stnId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
