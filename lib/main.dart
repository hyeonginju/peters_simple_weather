import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'app.dart';
import 'core/env/env.dart';
import 'features/widget/widget_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  // Widget: handle ↻ taps in a background isolate, sync on launch (throttled),
  // and schedule the OS-managed periodic refresh.
  await HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);
  unawaited(WidgetService.refreshPrimaryRegion(force: false));
  unawaited(WidgetService.scheduleAutoRefresh());

  runApp(ProviderScope(child: CleanWeatherApp()));
}
