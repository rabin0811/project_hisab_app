import 'package:flutter/material.dart';

import '../../data/models/enums.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';

/// Presentation metadata for [AccountType] (icon, label, semantic color).
extension AccountTypeStyleX on AccountType {
  IconData get icon => switch (this) {
    AccountType.bank => Icons.account_balance_outlined,
    AccountType.wallet => Icons.account_balance_wallet_outlined,
    AccountType.cash => Icons.payments_outlined,
  };

  String label(AppLocalizations l10n) => switch (this) {
    AccountType.bank => l10n.bank,
    AccountType.wallet => l10n.wallet,
    AccountType.cash => l10n.cash,
  };

  Color color(BuildContext context) => switch (this) {
    AccountType.bank => context.appColors.bank,
    AccountType.wallet => context.appColors.wallet,
    AccountType.cash => context.appColors.cash,
  };
}

/// Suggested names shown as quick-add chips when creating an account.
const Map<AccountType, List<String>> kAccountPresets = {
  AccountType.wallet: [
    'eSewa',
    'Khalti',
    'IME Pay',
    'Fonepay',
    'Smart Pay',
    'Connect IPS',
  ],
  AccountType.bank: [
    'Nabil Bank',
    'NIC Asia',
    'Global IME',
    'Rastriya Banijya',
    'Nepal Investment',
    'Sanima Bank',
    'Siddhartha Bank',
  ],
  AccountType.cash: [],
};
