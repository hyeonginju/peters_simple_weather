import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/widgets/weather_icon.dart';
import '../widget_service.dart';
import '../widget_settings.dart';

/// Lets the user pick the widget background style (dark/light/medium) and
/// opacity, with a live preview. Reachable both in-app (manage screen) and as
/// the widget's configuration Activity (long-press → 설정).
class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  static const _configChannel = MethodChannel('peters_weather/widget_config');

  WidgetSettings _settings = const WidgetSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetSettings.load().then((s) {
      if (!mounted) return;
      setState(() {
        _settings = s;
        _loaded = true;
      });
    });
  }

  Future<void> _save() async {
    await WidgetService.applySettings(_settings);
    // If launched as the widget config Activity, let native finish with OK.
    // In-app navigation falls through to pop().
    try {
      await _configChannel.invokeMethod('finish');
      return;
    } on PlatformException {
      // ignore — not in config mode
    } on MissingPluginException {
      // ignore — not in config mode
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('위젯 배경 설정')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text('미리보기', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textMuted)),
                const SizedBox(height: 10),
                _PreviewBackdrop(child: _WidgetPreview(settings: _settings)),
                const SizedBox(height: 28),
                Text('배경', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textMuted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final style in WidgetBgStyle.values) ...[
                      Expanded(
                        child: _StyleOption(
                          style: style,
                          selected: _settings.style == style,
                          onTap: () => setState(() => _settings = _settings.copyWith(style: style)),
                        ),
                      ),
                      if (style != WidgetBgStyle.values.last) const SizedBox(width: 10),
                    ],
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Text('투명도', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.textMuted)),
                    const Spacer(),
                    Text('${_settings.opacity}%',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: palette.point)),
                  ],
                ),
                Slider(
                  value: _settings.opacity.toDouble(),
                  max: 100,
                  divisions: 100,
                  label: '${_settings.opacity}%',
                  onChanged: (v) => setState(() => _settings = _settings.copyWith(opacity: v.round())),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  child: const Text('저장'),
                ),
              ],
            ),
    );
  }
}

/// Background style of the preview/widget.
({Color? solid, Gradient? gradient, bool light}) _bgFor(WidgetBgStyle style) {
  switch (style) {
    case WidgetBgStyle.dark:
      return (solid: const Color(0xFF121316), gradient: null, light: false);
    case WidgetBgStyle.light:
      return (solid: const Color(0xFFF5F6F8), gradient: null, light: true);
    case WidgetBgStyle.medium:
      return (
        solid: null,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8FA1BC), Color(0xFF717F99), Color(0xFF54607C)],
        ),
        light: false,
      );
  }
}

/// A decorative backdrop so the background opacity is actually visible.
class _PreviewBackdrop extends StatelessWidget {
  const _PreviewBackdrop({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE9B27A), Color(0xFF7B6C8F), Color(0xFF34455E)],
        ),
      ),
      child: child,
    );
  }
}

class _WidgetPreview extends StatelessWidget {
  const _WidgetPreview({required this.settings});
  final WidgetSettings settings;

  @override
  Widget build(BuildContext context) {
    final bg = _bgFor(settings.style);
    final primary = bg.light ? const Color(0xFF16181C) : Colors.white;
    final secondary = bg.light ? const Color(0xFF8A9098) : Colors.white.withValues(alpha: 0.7);
    final hours = ['13시', '14시', '15시', '16시', '17시'];
    final temps = ['24°', '24°', '23°', '23°', '22°'];

    return Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: settings.opacity / 100,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: bg.solid,
                gradient: bg.gradient,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: primary, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('영등포구', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primary)),
                  const Spacer(),
                  Text('09:30 업데이트', style: TextStyle(fontSize: 10, color: secondary)),
                  const SizedBox(width: 6),
                  Icon(Icons.refresh_rounded, size: 16, color: primary),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const WeatherIcon(type: WeatherIconType.sun, size: 40),
                  const SizedBox(width: 6),
                  Text('24°', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: primary)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < hours.length; i++)
                          Column(
                            children: [
                              Text(hours[i], style: TextStyle(fontSize: 10, color: secondary)),
                              const SizedBox(height: 2),
                              const WeatherIcon(type: WeatherIconType.partly, size: 18),
                              const SizedBox(height: 2),
                              Text(temps[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({required this.style, required this.selected, required this.onTap});

  final WidgetBgStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = _bgFor(style);
    final label = switch (style) {
      WidgetBgStyle.dark => '다크',
      WidgetBgStyle.light => '라이트',
      WidgetBgStyle.medium => '중간',
    };

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: bg.solid,
              gradient: bg.gradient,
              border: Border.all(
                color: selected ? palette.point : palette.cardBorder,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? Icon(Icons.check_circle, color: bg.light ? palette.point : Colors.white, size: 20)
                : null,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? palette.point : palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
