import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/widget/widget_service.dart';

class CleanWeatherApp extends StatefulWidget {
  CleanWeatherApp({super.key, GoRouter? router}) : router = router ?? createAppRouter();

  final GoRouter router;

  @override
  State<CleanWeatherApp> createState() => _CleanWeatherAppState();
}

class _CleanWeatherAppState extends State<CleanWeatherApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

  @override
  Widget build(BuildContext context) {
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
