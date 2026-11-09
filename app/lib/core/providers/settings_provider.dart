import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Overridden in `main()` with the loaded instance so settings can be read
/// synchronously on first frame (no theme/locale flash).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

@immutable
class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
    this.accentName = 'Teal',
  });

  final ThemeMode themeMode;
  final Locale locale;
  final String accentName;

  Color get seedColor => kAccentSeeds[accentName] ?? kDefaultSeed;

  /// `Rs.` for English, `रू` for Nepali.
  String get currencySymbol => locale.languageCode == 'ne' ? 'रू' : 'Rs.';

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    String? accentName,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      accentName: accentName ?? this.accentName,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _keyTheme = 'settings.themeMode';
  static const _keyLocale = 'settings.locale';
  static const _keyAccent = 'settings.accentName';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SettingsState build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final themeIndex = prefs.getInt(_keyTheme) ?? ThemeMode.system.index;
    return SettingsState(
      themeMode: ThemeMode.values[themeIndex.clamp(0, ThemeMode.values.length - 1)],
      locale: Locale(prefs.getString(_keyLocale) ?? 'en'),
      accentName: prefs.getString(_keyAccent) ?? 'Teal',
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(_keyTheme, mode.index);
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    await _prefs.setString(_keyLocale, locale.languageCode);
  }

  Future<void> setAccent(String name) async {
    state = state.copyWith(accentName: name);
    await _prefs.setString(_keyAccent, name);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
