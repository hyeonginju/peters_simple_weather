import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/region/models/region.dart';
import '../../../data/weather/mappers/daily_precipitation_total.dart';
import '../../../data/weather/mappers/daytime_average.dart';
import '../../../data/weather/models/daily_forecast.dart';
import '../../../data/weather/models/forecast_result.dart';
import '../../../data/weather/models/hourly_forecast.dart';
import '../../../data/weather/models/weather_snapshot.dart';
import '../../clothing/clothing_band_mapper.dart';
import '../../hourly_forecast/hourly_timeline_builder.dart';
import '../../hourly_forecast/widgets/hourly_forecast_card.dart';
import '../../region_picker/providers/region_providers.dart';
import '../../weekly_forecast/widgets/weekly_day_row.dart';
import '../providers/weather_providers.dart';
import '../widgets/clothing_card.dart';
import '../widgets/error_full_screen.dart';
import '../widgets/error_partial_overlay.dart';
import '../widgets/forecast_section_card.dart';
import '../widgets/region_header.dart';
import '../widgets/weather_hero.dart';
import '../widgets/weather_skeleton.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final savedRegionsAsync = ref.watch(savedRegionsProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            savedRegionsAsync.when(
              data: (regions) {
                if (regions.isEmpty) {
                  return _EmptyState(onAddRegion: () => context.push('/regions/add'));
                }
                return _RegionPager(
                  regions: regions,
                  pageController: _pageController,
                  onPageChanged: (index) => ref.read(activeRegionIndexProvider.notifier).set(index),
                  onArrowTap: _goToPage,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('지역을 불러오지 못했습니다: $error')),
            ),
            // Last-updated time overlaid top-left (active region's fetch time).
            const Positioned(
              top: 14,
              left: 20,
              child: _UpdatedLabel(),
            ),
            // Manage button overlaid top-right so it doesn't consume a row.
            Positioned(
              top: 2,
              right: 6,
              child: IconButton(
                tooltip: '내 지역 관리',
                onPressed: () => context.push('/regions'),
                icon: Icon(Icons.tune_rounded, size: 22, color: context.palette.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddRegion});

  final VoidCallback onAddRegion;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('아직 추가한 지역이 없어요.', style: TextStyle(fontSize: 15, color: palette.textSecondary)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onAddRegion, child: const Text('지역 추가')),
        ],
      ),
    );
  }
}

class _RegionPager extends StatelessWidget {
  const _RegionPager({
    required this.regions,
    required this.pageController,
    required this.onPageChanged,
    required this.onArrowTap,
  });

  final List<Region> regions;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onArrowTap;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: pageController,
      itemCount: regions.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: pageController,
          builder: (context, _) {
            final currentIndex = pageController.hasClients && pageController.page != null
                ? pageController.page!.round()
                : index;
            return Column(
              children: [
                const SizedBox(height: 12),
                RegionHeader(
                  provinceName: regions[index].provinceLabel,
                  regionName: regions[index].name,
                  pageCount: regions.length,
                  currentIndex: currentIndex,
                  onPrevious: index > 0 ? () => onArrowTap(index - 1) : null,
                  onNext: index < regions.length - 1 ? () => onArrowTap(index + 1) : null,
                ),
                const SizedBox(height: 16),
                Expanded(child: _RegionWeatherView(region: regions[index])),
              ],
            );
          },
        );
      },
    );
  }
}

/// 현재 활성 지역의 마지막 업데이트 시각을 좌상단에 표시한다.
class _UpdatedLabel extends ConsumerWidget {
  const _UpdatedLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final region = ref.watch(activeRegionProvider).asData?.value;
    if (region == null) return const SizedBox.shrink();
    final updated = ref.watch(regionLastUpdatedProvider(region));
    if (updated == null) return const SizedBox.shrink();
    return Text(
      formatUpdatedLabel(updated),
      style: TextStyle(fontSize: 11.5, color: context.palette.textMuted),
    );
  }
}

class _RegionWeatherView extends ConsumerWidget {
  const _RegionWeatherView({required this.region});

  final Region region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(forecastForProvider(region));

    Future<void> refresh() async {
      ref.read(weatherRepositoryProvider).invalidate(region);
      ref.invalidate(forecastForProvider(region));
      await ref.read(forecastForProvider(region).future);
    }

    return forecastAsync.when(
      data: (result) => switch (result) {
        ForecastFailure() => ErrorFullScreen(onRetry: refresh),
        ForecastSuccess(snapshot: final s, hourly: final h, daily: final d) =>
          RefreshIndicator(onRefresh: refresh, child: _WeatherContent(snapshot: s, hourly: h, daily: d)),
        ForecastPartialFailure(snapshot: final s, hourly: final h, daily: final d) =>
          RefreshIndicator(onRefresh: refresh, child: _WeatherContent(snapshot: s, hourly: h, daily: d)),
      },
      loading: () => const WeatherSkeleton(),
      error: (error, _) => ErrorFullScreen(onRetry: refresh),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({required this.snapshot, required this.hourly, required this.daily});

  final WeatherSnapshot snapshot;
  final List<HourlyForecast>? hourly;
  final List<DailyForecast>? daily;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hourlyList = hourly;
    final dailyList = daily;
    final today = _findToday(dailyList, now);

    final clothingBand = today == null
        ? null
        : mapTemperatureToClothingBand(
            resolveTargetTemperature(
              maxTemp: today.maxTemp,
              minTemp: today.minTemp,
              daytimeAverageTemp:
                  (hourlyList != null ? computeDaytimeAverageTemp(hourlyList, now) : null) ?? snapshot.temperature,
              month: now.month,
            ),
          );
    final precipitationTotal = hourlyList != null ? sumPrecipitationToday(hourlyList, now) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      child: Column(
        children: [
          WeatherHero(snapshot: snapshot, today: today, todayPrecipitationTotal: precipitationTotal),
          const SizedBox(height: 22),
          if (clothingBand != null) ...[
            ClothingCard(band: clothingBand),
            const SizedBox(height: 14),
          ],
          _HourlySection(snapshot: snapshot, hourly: hourlyList, now: now),
          const SizedBox(height: 14),
          _WeeklySection(daily: dailyList, today: now),
          const SizedBox(height: 14),
          const _AlertEntryButton(),
        ],
      ),
    );
  }

  DailyForecast? _findToday(List<DailyForecast>? daily, DateTime now) {
    if (daily == null) return null;
    for (final day in daily) {
      if (day.date.year == now.year && day.date.month == now.month && day.date.day == now.day) {
        return day;
      }
    }
    return null;
  }
}

/// 메인 하단 — 기상특보 발효 현황 페이지로 가는 버튼.
class _AlertEntryButton extends StatelessWidget {
  const _AlertEntryButton();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: () => context.push('/alerts'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.cardBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 20, color: palette.danger),
            const SizedBox(width: 10),
            Text(
              '기상특보 발효 현황',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 22, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

class _HourlySection extends StatelessWidget {
  const _HourlySection({required this.snapshot, required this.hourly, required this.now});

  final WeatherSnapshot snapshot;
  final List<HourlyForecast>? hourly;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final hourlyList = hourly;
    if (hourlyList == null) {
      final placeholder = ForecastSectionCard(
        title: '시간별 예보',
        child: const SizedBox(height: 150),
      );
      return ErrorPartialOverlay(message: '시간별 정보를 불러오지 못했습니다\n잠시 후 다시 시도해 주세요', child: placeholder);
    }

    return HourlyForecastCard(
      entries: buildHourlyTimeline(snapshot: snapshot, hourly: hourlyList, now: now),
      today: now,
    );
  }
}

class _WeeklySection extends StatelessWidget {
  const _WeeklySection({required this.daily, required this.today});

  final List<DailyForecast>? daily;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final dailyList = daily;
    final preview = dailyList ?? const <DailyForecast>[];
    final weekMin = preview.isEmpty ? 0.0 : preview.map((d) => d.minTemp).reduce((a, b) => a < b ? a : b);
    final weekMax = preview.isEmpty ? 1.0 : preview.map((d) => d.maxTemp).reduce((a, b) => a > b ? a : b);

    final card = ForecastSectionCard(
      title: '주간 예보',
      onTitleTap: dailyList == null ? null : () => GoRouter.of(context).push('/weekly'),
      titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      bodyPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < preview.length; i++)
            WeeklyDayRow(
              day: preview[i],
              today: today,
              weekMin: weekMin,
              weekMax: weekMax,
              showDivider: i != preview.length - 1,
            ),
          if (dailyList == null) const SizedBox(height: 72),
        ],
      ),
    );

    if (dailyList == null) {
      return ErrorPartialOverlay(message: '주간 예보를 불러오지 못했습니다\n잠시 후 다시 시도해 주세요', child: card);
    }
    return card;
  }
}
