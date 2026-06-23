import 'package:go_router/go_router.dart';

import '../../features/alerts/screens/alerts_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/region_picker/screens/region_manage_screen.dart';
import '../../features/region_picker/screens/region_picker_screen.dart';
import '../../features/settings/screens/theme_settings_screen.dart';
import '../../features/weekly_forecast/screens/weekly_forecast_screen.dart';
import '../../features/widget/screens/widget_settings_screen.dart';

/// Builds a fresh [GoRouter]. Each [CleanWeatherApp] instance gets its own
/// router rather than sharing one process-wide singleton, so widget tests
/// that build the app multiple times don't leak navigation state between
/// runs.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/regions',
        builder: (context, state) => const RegionManageScreen(),
      ),
      GoRoute(
        path: '/regions/add',
        builder: (context, state) => const RegionPickerScreen(),
      ),
      GoRoute(
        path: '/weekly',
        builder: (context, state) => const WeeklyForecastScreen(),
      ),
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const AlertsScreen(),
      ),
      GoRoute(
        path: '/widget-settings',
        builder: (context, state) => const WidgetSettingsScreen(),
      ),
      GoRoute(
        path: '/theme-settings',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
    ],
  );
}
