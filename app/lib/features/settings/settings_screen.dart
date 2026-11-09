import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/database.dart';
import '../../widgets/theme_toggle_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionTitle(l10n.appearance),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  trailing: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: 'en', label: Text(l10n.english)),
                      ButtonSegment(value: 'ne', label: Text(l10n.nepali)),
                    ],
                    selected: {settings.locale.languageCode},
                    onSelectionChanged: (s) =>
                        notifier.setLocale(Locale(s.first)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: Text(l10n.theme),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    onChanged: (m) {
                      if (m != null) notifier.setThemeMode(m);
                    },
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(l10n.themeSystem),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(l10n.themeLight),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(l10n.themeDark),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accentColor,
                        style: context.texts.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final entry in kAccentSeeds.entries)
                            _AccentDot(
                              color: entry.value,
                              selected: settings.accentName == entry.key,
                              onTap: () => notifier.setAccent(entry.key),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionTitle(l10n.profilesAndAccounts),
          Card(
            child: Column(
              children: [
                for (final profile in profiles) ...[
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: context.colors.secondaryContainer,
                      child: Text(
                        initialsOf(profile.name),
                        style: TextStyle(
                          color: context.colors.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(profile.name),
                    subtitle: Text(
                      _accountsSummary(l10n, [
                        for (final a in accounts)
                          if (a.profileId == profile.id) a,
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                ],
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(l10n.manageAccounts),
                  subtitle: Text(l10n.accountsHint),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/accounts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _SectionTitle(l10n.accountSection),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_sync_outlined),
              title: Text(l10n.signIn),
              subtitle: Text(l10n.signInSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showComingSoon(context),
            ),
          ),
          const SizedBox(height: 20),

          _SectionTitle(l10n.about),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.appTitle),
              subtitle: Text('${l10n.version} 1.0.0'),
              trailing: Text(
                l10n.appTagline,
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _accountsSummary(AppLocalizations l10n, List<Account> accounts) {
    if (accounts.isEmpty) return l10n.noAccounts;
    return accounts.map((a) => a.name).join(' · ');
  }

  void _showComingSoon(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.comingSoon)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: context.texts.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colors.primary,
        ),
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: context.colors.onSurface, width: 3)
              : null,
        ),
        child: selected
            ? Icon(Icons.check, color: onColor, size: 18)
            : null,
      ),
    );
  }
}
