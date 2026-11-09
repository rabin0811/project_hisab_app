import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/account_style.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/database.dart';
import '../../data/models/enums.dart';
import '../../widgets/empty_state.dart';
import 'account_form_sheet.dart';

/// Full account management: multiple banks, wallets and a cash account per
/// profile.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final entries = ref.watch(allEntriesProvider).value ?? const <Entry>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accounts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAccountForm(
          context,
          profileId: profiles.length == 1 ? profiles.first.id : null,
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.addAccount),
      ),
      body: profiles.isEmpty
          ? EmptyState(icon: Icons.account_balance_outlined, title: l10n.noAccounts)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                for (final profile in profiles)
                  _ProfileSection(
                    profile: profile,
                    accounts: [
                      for (final a in accounts)
                        if (a.profileId == profile.id) a,
                    ],
                    entries: entries,
                    symbol: settings.currencySymbol,
                  ),
              ],
            ),
    );
  }
}

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection({
    required this.profile,
    required this.accounts,
    required this.entries,
    required this.symbol,
  });

  final Profile profile;
  final List<Account> accounts;
  final List<Entry> entries;
  final String symbol;

  double _currentBalance(Account account) {
    var balance = account.openingBalance;
    for (final e in entries) {
      if (e.accountId != account.id) continue;
      if (e.kind.isCashIn) balance += e.amount;
      if (e.kind.isCashOut) balance -= e.amount;
    }
    return balance;
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Account account) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountMessage),
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
    if (confirmed ?? false) {
      await ref.read(accountRepositoryProvider).deleteAccount(account.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Text(
            profile.name,
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.primary,
            ),
          ),
        ),
        if (accounts.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.noAccounts),
              subtitle: Text(l10n.addAccountFirst),
              onTap: () => showAccountForm(context, profileId: profile.id),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < accounts.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
                  _AccountTile(
                    account: accounts[i],
                    currentBalance: _currentBalance(accounts[i]),
                    symbol: symbol,
                    onEdit: () =>
                        showAccountForm(context, existing: accounts[i]),
                    onDelete: () => _delete(context, ref, accounts[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.currentBalance,
    required this.symbol,
    required this.onEdit,
    required this.onDelete,
  });

  final Account account;
  final double currentBalance;
  final String symbol;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = account.type.color(context);

    return ListTile(
      onTap: onEdit,
      leading: CircleAvatar(
        backgroundColor: accent.withValues(alpha: 0.14),
        child: Icon(account.type.icon, color: accent, size: 20),
      ),
      title: Text(
        account.name,
        style: context.texts.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${account.type.label(l10n)}  ·  ${l10n.openingBalance}: '
        '${money(account.openingBalance, symbol: symbol)}',
        style: context.texts.bodySmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            money(currentBalance, symbol: symbol),
            style: context.texts.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') {
                onEdit();
              } else if (v == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.editAccount)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
    );
  }
}
