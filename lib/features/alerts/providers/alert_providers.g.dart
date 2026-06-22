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

@ProviderFor(alertStatus)
final alertStatusProvider = AlertStatusFamily._();

/// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.

final class AlertStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeatherAlertStatus>,
          WeatherAlertStatus,
          FutureOr<WeatherAlertStatus>
        >
    with
        $FutureModifier<WeatherAlertStatus>,
        $FutureProvider<WeatherAlertStatus> {
  /// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.
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
  $FutureProviderElement<WeatherAlertStatus> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WeatherAlertStatus> create(Ref ref) {
    final argument = this.argument as String;
    return alertStatus(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AlertStatusProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$alertStatusHash() => r'01862ac0583545a7f88195d97e6c1a3cb61e565f';

/// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.

final class AlertStatusFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WeatherAlertStatus>, String> {
  AlertStatusFamily._()
    : super(
        retry: null,
        name: r'alertStatusProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 관서(stnId) 권역의 특보 발효 현황. 지역/전국 토글에 따라 stnId가 달라진다.

  AlertStatusProvider call(String stnId) =>
      AlertStatusProvider._(argument: stnId, from: this);

  @override
  String toString() => r'alertStatusProvider';
}
