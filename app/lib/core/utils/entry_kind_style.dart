import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';
import '../../data/models/enums.dart';

/// Presentation metadata for each [EntryKind] (label, icon, semantic color).
extension EntryKindStyleX on EntryKind {
  IconData get icon => switch (this) {
    EntryKind.income => Icons.south_west,
    EntryKind.expense => Icons.north_east,
    EntryKind.profit => Icons.trending_up,
    EntryKind.lent => Icons.call_made,
    EntryKind.borrowed => Icons.call_received,
    EntryKind.repaidByThem => Icons.assignment_turned_in,
    EntryKind.repaidToThem => Icons.payments_outlined,
  };

  Color color(BuildContext context) {
    final app = context.appColors;
    return switch (this) {
      EntryKind.income => app.income,
      EntryKind.expense => app.expense,
      EntryKind.profit => app.profit,
      EntryKind.lent => app.negative,
      EntryKind.borrowed => app.positive,
      EntryKind.repaidByThem => app.positive,
      EntryKind.repaidToThem => app.negative,
    };
  }

  /// Whether the amount should be shown with a leading `+`/`-`.
  bool get isIncrease => isCashIn;

  String label(AppLocalizations l) => switch (this) {
    EntryKind.income => l.income,
    EntryKind.expense => l.expense,
    EntryKind.profit => l.profit,
    EntryKind.lent => l.lentTo,
    EntryKind.borrowed => l.borrowedFrom,
    EntryKind.repaidByThem => l.repaidByThem,
    EntryKind.repaidToThem => l.repaidToThem,
  };
}
