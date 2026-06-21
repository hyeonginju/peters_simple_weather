import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/region/models/region.dart';
import '../../../data/weather/models/daily_forecast.dart';
import '../../../data/weather/models/forecast_result.dart';
import '../../home/providers/weather_providers.dart';
import '../../home/widgets/error_full_screen.dart';
import '../widgets/weekly_chart.dart';

class WeeklyForecastScreen extends ConsumerWidget {
  const WeeklyForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRegionAsync = ref.watch(activeRegionProvider);

    return Scaffold(
      appBar: AppBar(),
      body: activeRegionAsync.when(
        data: (region) {
          if (region == null) {
            return const Center(child: Text('지역을 먼저 추가해 주세요.'));
          }
          return _WeeklyBody(region: region);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('지역 정보를 불러오지 못했습니다: $error')),
      ),
    );
  }
}

class _WeeklyBody extends ConsumerWidget {
  const _WeeklyBody({required this.region});

  final Region region;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final forecastAsync = ref.watch(forecastForProvider(region));

    return forecastAsync.when(
      data: (result) {
        final daily = switch (result) {
          ForecastSuccess(daily: final d) => d,
          ForecastPartialFailure(daily: final d) => d,
          ForecastFailure() => null,
        };
        if (daily == null || daily.isEmpty) {
          return ErrorFullScreen(onRetry: () => ref.invalidate(forecastForProvider(region)));
        }
        final week = daily.take(7).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '주간 예보',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: palette.textPrimary),
              ),
              const SizedBox(height: 8),
              _BAnBadge(palette: palette),
              const SizedBox(height: 16),
              _ChartCard(daily: week, palette: palette),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorFullScreen(onRetry: () => ref.invalidate(forecastForProvider(region))),
    );
  }
}

class _BAnBadge extends StatelessWidget {
  const _BAnBadge({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: palette.pointBg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('B안', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: palette.pointText)),
          const SizedBox(width: 6),
          Text('기온 추세 선그래프', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: palette.pointText)),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.daily, required this.palette});

  final List<DailyForecast> daily;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
        boxShadow: [
          BoxShadow(color: const Color(0xFF141828).withValues(alpha: 0.05), blurRadius: 14, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
            child: Row(
              children: [
                Text('기온 추세', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                const Spacer(),
                _LegendItem(color: palette.chartHigh, label: '최고', palette: palette),
                const SizedBox(width: 12),
                _LegendItem(color: palette.chartLow, label: '최저', palette: palette),
              ],
            ),
          ),
          const SizedBox(height: 8),
          WeeklyTrendChart(daily: daily, today: DateTime.now()),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label, required this.palette});

  final Color color;
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: palette.textMuted)),
      ],
    );
  }
}
