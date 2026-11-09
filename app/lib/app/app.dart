import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/gen/app_localizations.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class DailyKarobarApp extends ConsumerWidget {
  const DailyKarobarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seed: settings.seedColor),
      darkTheme: AppTheme.dark(seed: settings.seedColor),
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: appRouter,
    );
  }
}
