import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/database.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/theme_toggle_button.dart';
import 'person_form_sheet.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final peopleAsync = ref.watch(filteredPeopleProvider);
    final balances = ref.watch(personBalancesProvider);
    final summary = ref.watch(summaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.peopleTitle),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: l10n.addPerson,
            onPressed: () => showPersonForm(context),
            icon: const Icon(Icons.person_add_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: ref.read(peopleQueryProvider.notifier).update,
              decoration: InputDecoration(
                hintText: l10n.searchPeople,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          _PeopleSummary(summary: summary, symbol: settings.currencySymbol),
          Expanded(
            child: peopleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (people) {
                if (people.isEmpty) {
                  return EmptyState(
                    icon: Icons.people_outline,
                    title: l10n.noPeople,
                    subtitle: l10n.noPeopleHint,
                    action: FilledButton.icon(
                      onPressed: () => showPersonForm(context),
                      icon: const Icon(Icons.person_add_alt),
                      label: Text(l10n.addPerson),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                  itemCount: people.length,
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return _PersonTile(
                      person: person,
                      balance: balances[person.id] ?? 0,
                      symbol: settings.currencySymbol,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleSummary extends StatelessWidget {
  const _PeopleSummary({required this.summary, required this.symbol});

  final Summary summary;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _MiniCard(
              label: l10n.owedToMe,
              value: money(summary.owedToMe, symbol: symbol),
              color: app.positive,
              icon: Icons.south_west,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MiniCard(
              label: l10n.owedByMe,
              value: money(summary.owedByMe, symbol: symbol),
              color: app.negative,
              icon: Icons.north_east,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.person,
    required this.balance,
    required this.symbol,
  });

  final Person person;
  final double balance;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final app = context.appColors;
    final settled = balance.abs() < 0.005;
    final color = settled
        ? app.neutral
        : (balance > 0 ? app.positive : app.negative);

    return ListTile(
      onTap: () => context.push('/person/${person.id}'),
      leading: CircleAvatar(
        backgroundColor: context.colors.secondaryContainer,
        child: Text(
          initialsOf(person.name),
          style: TextStyle(
            color: context.colors.onSecondaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        person.name,
        style: context.texts.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        settled
            ? AppLocalizations.of(context).settledUp
            : (balance > 0
                  ? AppLocalizations.of(context).theyOweMe
                  : AppLocalizations.of(context).iOweThem),
        style: context.texts.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        money(balance.abs(), symbol: symbol),
        style: context.texts.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
