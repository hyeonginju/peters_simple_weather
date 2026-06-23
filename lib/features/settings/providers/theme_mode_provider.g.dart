// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// User-selected app-wide theme mode (system/light/dark), persisted in
/// shared_preferences. Defaults to following the device setting.

@ProviderFor(AppThemeMode)
final appThemeModeProvider = AppThemeModeProvider._();

/// User-selected app-wide theme mode (system/light/dark), persisted in
/// shared_preferences. Defaults to following the device setting.
final class AppThemeModeProvider
    extends $AsyncNotifierProvider<AppThemeMode, ThemeMode> {
  /// User-selected app-wide theme mode (system/light/dark), persisted in
  /// shared_preferences. Defaults to following the device setting.
  AppThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeModeHash();

  @$internal
  @override
  AppThemeMode create() => AppThemeMode();
}

String _$appThemeModeHash() => r'6478701dfd4a00579785947922247abb75af06b0';

/// User-selected app-wide theme mode (system/light/dark), persisted in
/// shared_preferences. Defaults to following the device setting.

abstract class _$AppThemeMode extends $AsyncNotifier<ThemeMode> {
  FutureOr<ThemeMode> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ThemeMode>, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThemeMode>, ThemeMode>,
              AsyncValue<ThemeMode>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
