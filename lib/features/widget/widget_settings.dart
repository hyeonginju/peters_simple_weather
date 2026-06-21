import 'package:shared_preferences/shared_preferences.dart';

enum WidgetBgStyle {
  dark,
  light,
  medium;

  static WidgetBgStyle fromName(String? name) =>
      WidgetBgStyle.values.where((e) => e.name == name).firstOrNull ?? WidgetBgStyle.medium;
}

/// User-configurable home-screen widget appearance: background style and
/// background opacity (0–100). Persisted in shared_preferences and mirrored
/// into home_widget shared storage for the native widget to read.
class WidgetSettings {
  final WidgetBgStyle style;
  final int opacity; // 0..100

  const WidgetSettings({this.style = WidgetBgStyle.medium, this.opacity = 100});

  static const _styleKey = 'widget_bg_style';
  static const _opacityKey = 'widget_bg_opacity';

  static Future<WidgetSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    // The widget config Activity writes settings from a separate Flutter
    // engine/isolate; reload from disk so the in-app screen isn't stale.
    await prefs.reload();
    return WidgetSettings(
      style: WidgetBgStyle.fromName(prefs.getString(_styleKey)),
      opacity: prefs.getInt(_opacityKey) ?? 100,
    );
  }

  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_styleKey, style.name);
    await prefs.setInt(_opacityKey, opacity);
  }

  WidgetSettings copyWith({WidgetBgStyle? style, int? opacity}) =>
      WidgetSettings(style: style ?? this.style, opacity: opacity ?? this.opacity);
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
