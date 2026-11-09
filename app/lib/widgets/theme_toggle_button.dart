import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/providers/settings_provider.dart';

/// A quick light/dark toggle for app bars.
///
/// Switches between [ThemeMode.light] and [ThemeMode.dark]. When the current
/// mode is [ThemeMode.system], the first tap switches to the opposite of the
/// platform's current brightness so the change is always immediately visible.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(settingsProvider).themeMode;
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);

    return IconButton(
      tooltip: isDark ? l10n.switchToLightMode : l10n.switchToDarkMode,
      onPressed: () => ref
          .read(settingsProvider.notifier)
          .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark),
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}
