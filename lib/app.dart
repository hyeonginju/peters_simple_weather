import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/providers/weather_providers.dart';
import 'features/push/push_service.dart';
import 'features/region_picker/providers/region_providers.dart';
import 'features/settings/providers/theme_mode_provider.dart';
import 'features/widget/widget_service.dart';

class CleanWeatherApp extends ConsumerStatefulWidget {
  CleanWeatherApp({super.key, GoRouter? router}) : router = router ?? createAppRouter();

  final GoRouter router;

  @override
  ConsumerState<CleanWeatherApp> createState() => _CleanWeatherAppState();
}

class _CleanWeatherAppState extends ConsumerState<CleanWeatherApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Self-heal: the representative region may have changed while the app
    // was closed (e.g. reordered then killed before the listener below ran).
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_syncPushTopic()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh the widget when the app returns to the foreground (throttled).
    // 포그라운드의 keepAlive WeatherRepository(10분 캐시)를 재사용한다 — 방금
    // 메인 화면에서 받아둔 데이터가 있으면 KMA를 다시 호출하지 않고 그대로
    // 위젯에 써서, 백그라운드 isolate가 별도 캐시로 중복 호출하던 것을 줄이고
    // 위젯이 일시적 429로 에러난 상태도 자가 치유한다.
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshWidgetOnResume());
    }
  }

  /// 포그라운드 복귀 시 위젯을 갱신하되, 일시적 실패(429 등) 시 최대 3번까지
  /// 재시도한다. 첫 시도는 포그라운드 캐시를 재사용(throttle 적용)하고, 재시도는
  /// 실패로 이미 refresh 타임스탬프가 찍혀 throttle에 막히므로 force로 우회한다.
  Future<void> _refreshWidgetOnResume() async {
    final repository = ref.read(weatherRepositoryProvider);
    if (await WidgetService.refreshPrimaryRegion(repository: repository, force: false)) {
      return;
    }
    for (var attempt = 1; attempt <= 3; attempt++) {
      await Future<void>.delayed(Duration(seconds: 2 * attempt));
      if (await WidgetService.refreshPrimaryRegion(repository: repository, force: true)) {
        return;
      }
    }
  }

  Future<void> _syncPushTopic() async {
    final regions = await ref.read(savedRegionsProvider.future);
    await PushService.syncTopicForRegion(regions.isEmpty ? null : regions.first);
  }

  @override
  Widget build(BuildContext context) {
    // Representative region (savedRegions.first) changed live — re-sync the
    // push topic (no-op until the user has visited the alerts screen once).
    ref.listen(savedRegionsProvider, (previous, next) {
      final previousFirst = (previous?.value?.isEmpty ?? true) ? null : previous!.value!.first;
      final nextFirst = (next.value?.isEmpty ?? true) ? null : next.value!.first;
      if (previousFirst?.id != nextFirst?.id) {
        unawaited(PushService.syncTopicForRegion(nextFirst));
      }
    });

    final themeMode = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'CleanWeather',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: widget.router,
    );
  }
}
