import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/region/models/region.dart';
import '../../../data/region/region_repository.dart';

part 'region_providers.g.dart';

@riverpod
RegionRepository regionRepository(Ref ref) => RegionRepository();

@riverpod
Future<List<Region>> allRegions(Ref ref) async {
  return ref.watch(regionRepositoryProvider).loadAllRegions();
}

@riverpod
class SavedRegions extends _$SavedRegions {
  @override
  Future<List<Region>> build() async {
    final repository = ref.watch(regionRepositoryProvider);
    final all = await ref.watch(allRegionsProvider.future);
    final savedIds = await repository.loadSavedRegionIds();

    final byId = {for (final region in all) region.id: region};
    return [for (final id in savedIds) if (byId.containsKey(id)) byId[id]!];
  }

  Future<void> addRegion(Region region) async {
    final current = await future;
    if (current.length >= maxSavedRegions || current.any((r) => r.id == region.id)) {
      return;
    }
    final updated = [...current, region];
    await _persist(updated);
    state = AsyncData(updated);
  }

  Future<void> removeRegion(String regionId) async {
    final current = await future;
    final updated = current.where((r) => r.id != regionId).toList();
    await _persist(updated);
    state = AsyncData(updated);
  }

  /// [newIndex] must already be adjusted for the removed item at
  /// [oldIndex] (i.e. as provided by `ReorderableListView.onReorderItem`).
  Future<void> reorder(int oldIndex, int newIndex) async {
    final current = [...await future];
    final region = current.removeAt(oldIndex);
    current.insert(newIndex, region);
    await _persist(current);
    state = AsyncData(current);
  }

  Future<void> _persist(List<Region> regions) async {
    final repository = ref.read(regionRepositoryProvider);
    await repository.saveRegionIds(regions.map((r) => r.id).toList());
  }
}
