import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/dates/dual_date.dart';
import '../core/l10n/gen/app_localizations.dart';
import '../core/providers/settings_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/entry_kind_style.dart';
import '../data/local/database.dart';
import 'amount_text.dart';

/// A single row for an [Entry] (ledger entry or people transaction).
class EntryTile extends ConsumerWidget {
  const EntryTile({
    required this.entry,
    this.showDate = false,
    this.subtitleOverride,
    this.onTap,
    super.key,
  });

  final Entry entry;
  final bool showDate;
  final String? subtitleOverride;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final colors = context.colors;
    final accent = entry.kind.color(context);
    final language = languageForLocale(settings.locale.languageCode);

    final title = (entry.category?.trim().isNotEmpty ?? false)
        ? entry.category!
        : entry.kind.label(l10n);

    final parts = <String>[];
    if (subtitleOverride != null) {
      parts.add(subtitleOverride!);
    } else {
      parts.add(entry.kind.label(l10n));
      if (entry.note?.trim().isNotEmpty ?? false) parts.add(entry.note!.trim());
    }
    if (showDate) {
      parts.add(DualDate(entry.date).bsLong(language));
    }

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(entry.kind.icon, size: 20, color: accent),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        parts.join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      trailing: AmountText(
        value: entry.amount,
        symbol: settings.currencySymbol,
        showSign: true,
        color: accent,
        style: context.texts.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
