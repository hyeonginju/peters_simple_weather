import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/push/push_service.dart';
import 'features/region_picker/providers/region_providers.dart';
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
    if (state == AppLifecycleState.resumed) {
      unawaited(WidgetService.refreshPrimaryRegion(force: false));
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

    return MaterialApp.router(
      title: 'CleanWeather',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: widget.router,
    );
  }
}
