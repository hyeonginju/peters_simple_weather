// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'region_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(regionRepository)
final regionRepositoryProvider = RegionRepositoryProvider._();

final class RegionRepositoryProvider
    extends
        $FunctionalProvider<
          RegionRepository,
          RegionRepository,
          RegionRepository
        >
    with $Provider<RegionRepository> {
  RegionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'regionRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$regionRepositoryHash();

  @$internal
  @override
  $ProviderElement<RegionRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  RegionRepository create(Ref ref) {
    return regionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RegionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RegionRepository>(value),
    );
  }
}

String _$regionRepositoryHash() => r'283ac709e89615faee6093144441628e22aa1218';

@ProviderFor(allRegions)
final allRegionsProvider = AllRegionsProvider._();

final class AllRegionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Region>>,
          List<Region>,
          FutureOr<List<Region>>
        >
    with $FutureModifier<List<Region>>, $FutureProvider<List<Region>> {
  AllRegionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allRegionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allRegionsHash();

  @$internal
  @override
  $FutureProviderElement<List<Region>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Region>> create(Ref ref) {
    return allRegions(ref);
  }
}

String _$allRegionsHash() => r'b6ec0cfba966c50271889a44f7114196708a6405';

@ProviderFor(SavedRegions)
final savedRegionsProvider = SavedRegionsProvider._();

final class SavedRegionsProvider
    extends $AsyncNotifierProvider<SavedRegions, List<Region>> {
  SavedRegionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedRegionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedRegionsHash();

  @$internal
  @override
  SavedRegions create() => SavedRegions();
}

String _$savedRegionsHash() => r'b1660de4dd289f6e21304e8367ef0baa14359c65';

abstract class _$SavedRegions extends $AsyncNotifier<List<Region>> {
  FutureOr<List<Region>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Region>>, List<Region>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Region>>, List<Region>>,
              AsyncValue<List<Region>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
