import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates/dual_date.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/database.dart';
import '../../data/models/enums.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/entry_tile.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/theme_toggle_button.dart';
import '../ledger/entry_form_sheet.dart';
import '../people/person_form_sheet.dart';
import 'dashboard_charts.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final summary = ref.watch(summaryProvider);
    final entries = ref.watch(entriesProvider).value ?? const <Entry>[];
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];
    final active = ref.watch(activeProfileProvider);
    final scope = ref.watch(profileScopeProvider);
    final symbol = settings.currencySymbol;
    final today = DualDate.today();
    final language = languageForLocale(settings.locale.languageCode);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // Header: date + title.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appTitle,
                        style: context.texts.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${today.bsLong(language)}  ·  ${today.adLong}',
                        style: context.texts.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const ThemeToggleButton(),
              ],
            ),
            const SizedBox(height: 12),

            if (profiles.isNotEmpty)
              _ProfileSwitcher(
                profiles: profiles,
                active: active,
                onChanged: (id) =>
                    ref.read(activeProfileProvider.notifier).select(id),
              ),
            const SizedBox(height: 12),

            // Summary grid.
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.55,
              children: [
                SummaryCard(
                  label: l10n.cashInHand,
                  value: money(summary.cashInHand, symbol: symbol),
                  icon: Icons.account_balance_wallet_outlined,
                  accent: context.appColors.cash,
                ),
                SummaryCard(
                  label: l10n.netWorth,
                  value: money(summary.netWorth, symbol: symbol),
                  icon: Icons.savings_outlined,
                  accent: context.colors.primary,
                ),
                SummaryCard(
                  label: l10n.owedToMe,
                  value: money(summary.owedToMe, symbol: symbol),
                  icon: Icons.south_west,
                  accent: context.appColors.positive,
                ),
                SummaryCard(
                  label: l10n.owedByMe,
                  value: money(summary.owedByMe, symbol: symbol),
                  icon: Icons.north_east,
                  accent: context.appColors.negative,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick actions.
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.north_east,
                    label: l10n.addExpense,
                    color: context.appColors.expense,
                    onTap: () => _addEntry(
                      context,
                      ref,
                      scope,
                      EntryKind.expense,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.south_west,
                    label: l10n.addIncome,
                    color: context.appColors.income,
                    onTap: () => _addEntry(
                      context,
                      ref,
                      scope,
                      EntryKind.income,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.person_add_alt,
                    label: l10n.addPerson,
                    color: context.colors.primary,
                    onTap: () => showPersonForm(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            DashboardCharts(entries: entries, symbol: symbol),
            const SizedBox(height: 20),

            Row(
              children: [
                Text(
                  l10n.recentActivity,
                  style: context.texts.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: l10n.noRecentActivity,
                  subtitle: l10n.noRecentActivityHint,
                ),
              )
            else
              for (final entry in entries.take(8))
                EntryTile(entry: entry, showDate: true),
          ],
        ),
      ),
    );
  }

  Future<void> _addEntry(
    BuildContext context,
    WidgetRef ref,
    List<int> scope,
    EntryKind kind,
  ) async {
    if (scope.isEmpty) return;
    await showEntryForm(
      context,
      profileId: scope.first,
      allowedKinds: const [
        EntryKind.expense,
        EntryKind.income,
        EntryKind.profit,
      ],
      initialKind: kind,
    );
  }
}

class _ProfileSwitcher extends StatelessWidget {
  const _ProfileSwitcher({
    required this.profiles,
    required this.active,
    required this.onChanged,
  });

  final List<Profile> profiles;
  final int? active;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<int?>(
        showSelectedIcon: false,
        segments: [
          for (final p in profiles)
            ButtonSegment(value: p.id, label: Text(p.name)),
          ButtonSegment(value: null, label: Text(l10n.profileBoth)),
        ],
        selected: {active},
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
