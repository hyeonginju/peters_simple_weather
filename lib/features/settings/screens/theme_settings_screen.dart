import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../providers/theme_mode_provider.dart';

/// Lets the user pick the app's own light/dark mode, independent of the
/// device-wide setting. Selection applies immediately.
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final current = ref.watch(appThemeModeProvider).value ?? ThemeMode.system;

    return Scaffold(
      appBar: AppBar(title: const Text('화면 모드')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final mode in ThemeMode.values) ...[
            _ModeOption(
              mode: mode,
              selected: current == mode,
              palette: palette,
              onTap: () => ref.read(appThemeModeProvider.notifier).setMode(mode),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({required this.mode, required this.selected, required this.palette, required this.onTap});

  final ThemeMode mode;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (mode) {
      ThemeMode.system => (Icons.brightness_auto_rounded, '시스템 설정 따르기'),
      ThemeMode.light => (Icons.light_mode_rounded, '라이트'),
      ThemeMode.dark => (Icons.dark_mode_rounded, '다크'),
    };

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? palette.point : palette.cardBorder, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: selected ? palette.point : palette.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
            ),
            if (selected) Icon(Icons.check_circle, color: palette.point, size: 20),
          ],
        ),
      ),
    );
  }
}
