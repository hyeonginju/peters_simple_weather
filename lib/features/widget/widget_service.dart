import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../core/env/env.dart';
import '../../core/utils/weather_icon_mapper.dart';
import '../../data/region/models/region.dart';
import '../../data/region/region_repository.dart';
import '../../data/weather/models/daily_forecast.dart';
import '../../data/weather/models/forecast_result.dart';
import '../../data/weather/models/hourly_forecast.dart';
import '../../data/weather/models/weather_snapshot.dart';
import '../../data/weather/weather_repository.dart';
import '../../core/utils/date_formatter.dart';
import 'widget_settings.dart';

const _pkg = 'com.peterskim.peters_simple_weather';
const _providers = ['WeatherWidgetProvider', 'WeatherWidgetSmallProvider'];

/// Minimum gap between automatic refreshes (manual ↻ ignores this).
const _throttle = Duration(minutes: 10);
const _lastRefreshKey = 'widget_last_refresh';

/// Bridges the app's weather data to the native Android home-screen widget via
/// [home_widget]'s shared storage. Designed to run both in the foreground
/// (engine alive) and in a headless background isolate (widget ↻ button), so
/// the refresh works without opening the app — matching the spec's On-Demand
/// 수동 동기화 (no background polling).
class WidgetService {
  WidgetService._();

  /// Fetches the primary (first saved) region's forecast and writes it to the
  /// widget. Safe to call from a background isolate.
  ///
  /// When [force] is false (automatic triggers: app resume, WorkManager) the
  /// fetch is skipped if the last refresh was within [_throttle] — this caps
  /// API calls regardless of how often the screen turns on. The manual ↻
  /// button passes [force] true.
  static Future<void> refreshPrimaryRegion({WeatherRepository? repository, bool force = true}) async {
    WidgetsFlutterBinding.ensureInitialized();

    // Background isolates (widget ↻, WorkManager) never run main(), so the KMA
    // serviceKey from .env isn't loaded there. Load it here so the direct KMA
    // calls authenticate. Idempotent — harmless when already loaded in the app.
    await Env.load();

    // Keep background-style settings mirrored into widget storage.
    await _saveSettingsKeys(await WidgetSettings.load());

    if (!force && await _isThrottled()) return;

    final regionRepo = RegionRepository();
    final savedIds = await regionRepo.loadSavedRegionIds();
    if (savedIds.isEmpty) {
      await _writeEmpty();
      return;
    }

    final all = await regionRepo.loadAllRegions();
    Region? region;
    for (final r in all) {
      if (r.id == savedIds.first) {
        region = r;
        break;
      }
    }
    if (region == null) {
      await _writeEmpty();
      return;
    }

    try {
      final result = await (repository ?? WeatherRepository()).fetch(region);
      await writeForecast(region, result);
    } catch (_) {
      await _writeError(region);
    }
    await _markRefreshed();
  }

  static Future<bool> _isThrottled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final last = prefs.getInt(_lastRefreshKey);
    if (last == null) return false;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed < _throttle.inMilliseconds;
  }

  static Future<void> _markRefreshed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastRefreshKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Writes an already-loaded forecast (foreground path, no extra fetch).
  static Future<void> writeForecast(Region region, ForecastResult result) async {
    switch (result) {
      case ForecastFailure():
        await _writeError(region);
      case ForecastSuccess(snapshot: final s, hourly: final h, daily: final d):
        await _writeData(region, s, h, d);
      case ForecastPartialFailure(snapshot: final s, hourly: final h, daily: final d):
        await _writeData(region, s, h ?? const [], d);
    }
  }

  static Future<void> _writeData(
    Region region,
    WeatherSnapshot snapshot,
    List<HourlyForecast> hourly,
    List<DailyForecast>? daily,
  ) async {
    final now = DateTime.now();
    final today = _findToday(daily, now);
    // Widget rule: show from the next forecast hour onward (drop "지금").
    final slots = (hourly.where((h) => h.time.isAfter(now)).toList()
          ..sort((a, b) => a.time.compareTo(b.time)))
        .take(5)
        .toList();

    await _save({
      'w_has_data': 'true',
      'w_error': 'false',
      'w_loading': 'false',
      'w_region': region.name,
      'w_temp': '${snapshot.temperature.round()}°',
      'w_condition': weatherConditionLabel(snapshot.sky, snapshot.precipitationType),
      'w_icon': weatherIconTypeFor(snapshot.sky, snapshot.precipitationType).name,
      'w_minmax': today != null ? '${today.minTemp.round()}° / ${today.maxTemp.round()}°' : '',
      'w_pop': '강수 ${today?.popPercent ?? snapshot.precipitationProbability}%',
      'w_updated': '${_two(now.hour)}:${_two(now.minute)} 업데이트',
      for (var i = 0; i < 5; i++) ...{
        'w_h${i}_label': i < slots.length ? formatHourLabel(slots[i].time) : '',
        'w_h${i}_icon': i < slots.length
            ? weatherIconTypeFor(slots[i].sky, slots[i].precipitationType).name
            : '',
        'w_h${i}_temp': i < slots.length ? '${slots[i].temperature.round()}°' : '',
      },
    });
    await _update();
  }

  static Future<void> _writeError(Region region) async {
    await _save({
      'w_has_data': 'true',
      'w_error': 'true',
      'w_loading': 'false',
      'w_region': region.name,
      'w_updated': '업데이트 실패',
    });
    await _update();
  }

  static Future<void> _writeEmpty() async {
    await _save({'w_has_data': 'false', 'w_error': 'false', 'w_loading': 'false'});
    await _update();
  }

  /// Marks the widget(s) as loading (spinner) before a manual refresh fetch.
  static Future<void> setLoading() async {
    await _save({'w_loading': 'true'});
    await _update();
  }

  static const _periodicTaskName = 'widget-auto-refresh';

  /// Registers the OS-managed periodic background refresh (battery-friendly,
  /// network-gated). Each run is throttle-guarded, so the effective API rate
  /// stays low regardless of how often the OS wakes it.
  static Future<void> scheduleAutoRefresh() async {
    await Workmanager().initialize(widgetWorkmanagerCallback);
    await Workmanager().registerPeriodicTask(
      _periodicTaskName,
      'widgetAutoRefresh',
      frequency: const Duration(minutes: 30),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// Persists the appearance settings and refreshes the widget(s) so the
  /// new background style/opacity show immediately.
  static Future<void> applySettings(WidgetSettings settings) async {
    await settings.persist();
    await _saveSettingsKeys(settings);
    await _update();
  }

  static Future<void> _saveSettingsKeys(WidgetSettings s) async {
    await _save({'w_bg_style': s.style.name, 'w_bg_opacity': s.opacity.toString()});
  }

  static Future<void> _save(Map<String, String> data) async {
    for (final entry in data.entries) {
      await HomeWidget.saveWidgetData<String>(entry.key, entry.value);
    }
  }

  static Future<void> _update() async {
    for (final name in _providers) {
      await HomeWidget.updateWidget(androidName: name, qualifiedAndroidName: '$_pkg.$name');
    }
  }

  static DailyForecast? _findToday(List<DailyForecast>? daily, DateTime now) {
    if (daily == null) return null;
    for (final d in daily) {
      if (d.date.year == now.year && d.date.month == now.month && d.date.day == now.day) return d;
    }
    return null;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}

/// Background entry point invoked by [home_widget] when the widget's ↻ button
/// is tapped. Must be a top-level function annotated for AOT retention.
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  if (uri?.host == 'refresh') {
    // Manual ↻ — show spinner, force a fetch (ignores throttle).
    await WidgetService.setLoading();
    await WidgetService.refreshPrimaryRegion(force: true);
  }
}

/// WorkManager entry point for the periodic auto-refresh. Throttled.
@pragma('vm:entry-point')
void widgetWorkmanagerCallback() {
  Workmanager().executeTask((task, inputData) async {
    await WidgetService.refreshPrimaryRegion(force: false);
    return true;
  });
}
