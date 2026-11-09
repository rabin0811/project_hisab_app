import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/database.dart';
import '../../data/models/enums.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/entry_tile.dart';
import '../ledger/entry_form_sheet.dart';
import 'person_form_sheet.dart';

class PersonDetailScreen extends ConsumerWidget {
  const PersonDetailScreen({required this.personId, super.key});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final people = ref.watch(peopleProvider).value ?? const <Person>[];
    final person = people.where((p) => p.id == personId).firstOrNull;
    final entriesAsync = ref.watch(personEntriesProvider(personId));

    if (person == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: l10n.cantFindPerson,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(person.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await showPersonForm(context, existing: person);
              } else if (value == 'delete') {
                final confirmed = await _confirmDelete(context);
                if (confirmed) {
                  await ref
                      .read(personRepositoryProvider)
                      .deletePerson(person.id);
                  if (context.mounted) context.pop();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.editPerson)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTransaction(context, ref, person),
        icon: const Icon(Icons.add),
        label: Text(l10n.addTransaction),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (entries) {
          var balance = 0.0;
          for (final e in entries) {
            balance += e.kind.personBalanceSign * e.amount;
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              _BalanceCard(balance: balance, symbol: settings.currencySymbol),
              const SizedBox(height: 16),
              Text(
                l10n.runningBalance,
                style: context.texts.titleSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: EmptyState(
                    icon: Icons.history,
                    title: l10n.noTransactionsWithPerson,
                    action: FilledButton.icon(
                      onPressed: () => _addTransaction(context, ref, person),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addTransaction),
                    ),
                  ),
                )
              else
                for (final entry in entries)
                  EntryTile(
                    entry: entry,
                    showDate: true,
                    onTap: () => _editTransaction(context, person, entry),
                  ),
            ],
          );
        },
      ),
    );
  }

  static const _peopleKinds = [
    EntryKind.lent,
    EntryKind.borrowed,
    EntryKind.repaidByThem,
    EntryKind.repaidToThem,
  ];

  Future<void> _addTransaction(
    BuildContext context,
    WidgetRef ref,
    Person person,
  ) async {
    await showEntryForm(
      context,
      profileId: person.profileId,
      allowedKinds: _peopleKinds,
      initialKind: EntryKind.lent,
      personId: person.id,
      personName: person.name,
    );
  }

  Future<void> _editTransaction(
    BuildContext context,
    Person person,
    Entry entry,
  ) async {
    await showEntryForm(
      context,
      profileId: person.profileId,
      allowedKinds: _peopleKinds,
      personId: person.id,
      personName: person.name,
      existing: entry,
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deletePersonTitle),
        content: Text(l10n.deletePersonMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.symbol});

  final double balance;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final app = context.appColors;
    final settled = balance.abs() < 0.005;
    final color = settled
        ? app.neutral
        : (balance > 0 ? app.positive : app.negative);
    final label = settled
        ? l10n.settledUp
        : (balance > 0 ? l10n.theyOweMe : l10n.iOweThem);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.texts.labelLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          Text(
            money(balance.abs(), symbol: symbol),
            style: context.texts.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
