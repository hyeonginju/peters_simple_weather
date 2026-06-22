import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/region/models/region.dart';
import '../../../data/region/region_repository.dart';
import '../providers/region_providers.dart';

/// 지역 추가 화면. 검색창에 시/군/구를 바로 검색해 결과를 탭하면 즉시 추가된다
/// (1단계 통합). 검색이 비어 있으면 시/도 → 시/군/구 드릴다운으로 둘러볼 수도
/// 있고, 어느 쪽이든 항목을 탭하면 바로 추가된다.
class RegionPickerScreen extends ConsumerStatefulWidget {
  const RegionPickerScreen({super.key});

  @override
  ConsumerState<RegionPickerScreen> createState() => _RegionPickerScreenState();
}

class _RegionPickerScreenState extends ConsumerState<RegionPickerScreen> {
  String? _province; // browse drill-down (when search is empty)
  String _query = '';

  bool get _searching => _query.trim().isNotEmpty;

  void _back() {
    if (_province != null) {
      setState(() => _province = null);
    } else {
      context.pop();
    }
  }

  Future<void> _add(Region region) async {
    final current = ref.read(savedRegionsProvider).value ?? const [];
    if (current.any((r) => r.id == region.id)) return;
    if (current.length >= maxSavedRegions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지역은 최대 10개까지 추가할 수 있어요.')),
      );
      return;
    }
    await ref.read(savedRegionsProvider.notifier).addRegion(region);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final allRegionsAsync = ref.watch(allRegionsProvider);

    return Scaffold(
      body: SafeArea(
        child: allRegionsAsync.when(
          data: (all) {
            final repo = ref.read(regionRepositoryProvider);
            final savedIds = ref.watch(savedRegionsProvider).value?.map((r) => r.id).toSet() ?? const <String>{};
            return Column(
              children: [
                _Header(
                  title: _province ?? '지역 추가',
                  showBack: _province != null,
                  onBack: _back,
                  palette: palette,
                ),
                _SearchBox(
                  hint: '시/군/구 검색 (예: 유성구, 해운대구)',
                  onChanged: (q) => setState(() => _query = q),
                  palette: palette,
                ),
                Expanded(child: _buildList(repo, all, savedIds, palette)),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('지역 데이터를 불러오지 못했습니다: $error')),
        ),
      ),
    );
  }

  Widget _buildList(RegionRepository repo, List<Region> all, Set<String> savedIds, AppPalette palette) {
    if (_searching) {
      final q = _query.trim();
      final results = all.where((r) => r.name.contains(q) || r.province.contains(q)).toList();
      if (results.isEmpty) {
        return Center(child: Text('검색 결과가 없어요.', style: TextStyle(color: palette.textMuted)));
      }
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: results.length,
        itemBuilder: (context, i) => _RegionRow(
          title: results[i].name,
          subtitle: results[i].provinceLabel,
          saved: savedIds.contains(results[i].id),
          palette: palette,
          onTap: () => _add(results[i]),
        ),
      );
    }

    final province = _province;
    if (province == null) {
      final provinces = repo.distinctProvinces(all);
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: provinces.length,
        itemBuilder: (context, i) => _RegionRow(
          title: provinces[i],
          trailingChevron: true,
          palette: palette,
          onTap: () => setState(() => _province = provinces[i]),
        ),
      );
    }

    final districts = repo.districtsForProvince(all, province);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: districts.length,
      itemBuilder: (context, i) => _RegionRow(
        title: districts[i].name,
        saved: savedIds.contains(districts[i].id),
        palette: palette,
        onTap: () => _add(districts[i]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.showBack, required this.onBack, required this.palette});

  final String title;
  final bool showBack;
  final VoidCallback onBack;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Text(showBack ? '‹' : '✕', style: TextStyle(fontSize: 22, height: 1, color: palette.textPrimary)),
          ),
          Expanded(
            child: Center(
              child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: palette.textPrimary)),
            ),
          ),
          const SizedBox(width: 22),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint, required this.onChanged, required this.palette});

  final String hint;
  final ValueChanged<String> onChanged;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        decoration: BoxDecoration(color: palette.searchBg, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 18, color: palette.textMuted),
            const SizedBox(width: 9),
            Expanded(
              child: TextField(
                autofocus: false,
                onChanged: onChanged,
                style: TextStyle(fontSize: 14, color: palette.textPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 14, color: palette.textMuted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionRow extends StatelessWidget {
  const _RegionRow({
    required this.title,
    required this.palette,
    required this.onTap,
    this.subtitle,
    this.saved = false,
    this.trailingChevron = false,
  });

  final String title;
  final String? subtitle;
  final AppPalette palette;
  final VoidCallback onTap;
  final bool saved;
  final bool trailingChevron;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saved ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: palette.divider))),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: saved ? FontWeight.w700 : FontWeight.w500,
                    color: saved ? palette.textMuted : palette.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 12, color: palette.textMuted)),
                ],
              ],
            ),
            const Spacer(),
            if (saved)
              Row(
                children: [
                  Icon(Icons.check_rounded, size: 16, color: palette.point),
                  const SizedBox(width: 4),
                  Text('추가됨', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: palette.point)),
                ],
              )
            else if (trailingChevron)
              Text('›', style: TextStyle(fontSize: 18, color: palette.textFaint))
            else
              Icon(Icons.add_rounded, size: 20, color: palette.point),
          ],
        ),
      ),
    );
  }
}
