// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive — WeatherRepository는 region.id별로 10분 TTL 캐시를 들고 있다.
/// autoDispose였다면 지역 전환마다 forecastFor가 폐기되며 이 provider도
/// 함께 재생성되어 캐시가 매번 날아간다.

@ProviderFor(weatherRepository)
final weatherRepositoryProvider = WeatherRepositoryProvider._();

/// keepAlive — WeatherRepository는 region.id별로 10분 TTL 캐시를 들고 있다.
/// autoDispose였다면 지역 전환마다 forecastFor가 폐기되며 이 provider도
/// 함께 재생성되어 캐시가 매번 날아간다.

final class WeatherRepositoryProvider
    extends
        $FunctionalProvider<
          WeatherRepository,
          WeatherRepository,
          WeatherRepository
        >
    with $Provider<WeatherRepository> {
  /// keepAlive — WeatherRepository는 region.id별로 10분 TTL 캐시를 들고 있다.
  /// autoDispose였다면 지역 전환마다 forecastFor가 폐기되며 이 provider도
  /// 함께 재생성되어 캐시가 매번 날아간다.
  WeatherRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weatherRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weatherRepositoryHash();

  @$internal
  @override
  $ProviderElement<WeatherRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WeatherRepository create(Ref ref) {
    return weatherRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeatherRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeatherRepository>(value),
    );
  }
}

String _$weatherRepositoryHash() => r'91513f9b830021e64fe6b6b34e1dfc9b70ff4952';

/// Keyed by region — only the active region's screen watches this, so
/// Riverpod's autoDispose semantics naturally implement the spec's
/// "진입 시점에만 API 요청" lazy-fetch requirement: switching away from a
/// region disposes its provider instance instead of polling in the background.
/// 실제 네트워크 요청 여부는 WeatherRepository의 10분 TTL 캐시가 결정한다.

@ProviderFor(forecastFor)
final forecastForProvider = ForecastForFamily._();

/// Keyed by region — only the active region's screen watches this, so
/// Riverpod's autoDispose semantics naturally implement the spec's
/// "진입 시점에만 API 요청" lazy-fetch requirement: switching away from a
/// region disposes its provider instance instead of polling in the background.
/// 실제 네트워크 요청 여부는 WeatherRepository의 10분 TTL 캐시가 결정한다.

final class ForecastForProvider
    extends
        $FunctionalProvider<
          AsyncValue<ForecastResult>,
          ForecastResult,
          FutureOr<ForecastResult>
        >
    with $FutureModifier<ForecastResult>, $FutureProvider<ForecastResult> {
  /// Keyed by region — only the active region's screen watches this, so
  /// Riverpod's autoDispose semantics naturally implement the spec's
  /// "진입 시점에만 API 요청" lazy-fetch requirement: switching away from a
  /// region disposes its provider instance instead of polling in the background.
  /// 실제 네트워크 요청 여부는 WeatherRepository의 10분 TTL 캐시가 결정한다.
  ForecastForProvider._({
    required ForecastForFamily super.from,
    required Region super.argument,
  }) : super(
         retry: null,
         name: r'forecastForProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$forecastForHash();

  @override
  String toString() {
    return r'forecastForProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ForecastResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ForecastResult> create(Ref ref) {
    final argument = this.argument as Region;
    return forecastFor(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ForecastForProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$forecastForHash() => r'47245f11e8d6dbb9ae9fcc77d49b62a5cec28d64';

/// Keyed by region — only the active region's screen watches this, so
/// Riverpod's autoDispose semantics naturally implement the spec's
/// "진입 시점에만 API 요청" lazy-fetch requirement: switching away from a
/// region disposes its provider instance instead of polling in the background.
/// 실제 네트워크 요청 여부는 WeatherRepository의 10분 TTL 캐시가 결정한다.

final class ForecastForFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ForecastResult>, Region> {
  ForecastForFamily._()
    : super(
        retry: null,
        name: r'forecastForProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keyed by region — only the active region's screen watches this, so
  /// Riverpod's autoDispose semantics naturally implement the spec's
  /// "진입 시점에만 API 요청" lazy-fetch requirement: switching away from a
  /// region disposes its provider instance instead of polling in the background.
  /// 실제 네트워크 요청 여부는 WeatherRepository의 10분 TTL 캐시가 결정한다.

  ForecastForProvider call(Region region) =>
      ForecastForProvider._(argument: region, from: this);

  @override
  String toString() => r'forecastForProvider';
}

@ProviderFor(ActiveRegionIndex)
final activeRegionIndexProvider = ActiveRegionIndexProvider._();

final class ActiveRegionIndexProvider
    extends $NotifierProvider<ActiveRegionIndex, int> {
  ActiveRegionIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRegionIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeRegionIndexHash();

  @$internal
  @override
  ActiveRegionIndex create() => ActiveRegionIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activeRegionIndexHash() => r'aaad8b4179587b980d8f5452053db08fb4305f6b';

abstract class _$ActiveRegionIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(activeRegion)
final activeRegionProvider = ActiveRegionProvider._();

final class ActiveRegionProvider
    extends $FunctionalProvider<AsyncValue<Region?>, Region?, FutureOr<Region?>>
    with $FutureModifier<Region?>, $FutureProvider<Region?> {
  ActiveRegionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRegionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeRegionHash();

  @$internal
  @override
  $FutureProviderElement<Region?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Region?> create(Ref ref) {
    return activeRegion(ref);
  }
}

String _$activeRegionHash() => r'c149caaa822e2acba795a63f57e1c31e5063bf46';
