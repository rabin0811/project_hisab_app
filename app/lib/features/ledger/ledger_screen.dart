import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nepali_utils/nepali_utils.dart' show Language;

import '../../core/dates/dual_date.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/database.dart';
import '../../data/models/enums.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/entry_tile.dart';
import '../../widgets/theme_toggle_button.dart';
import 'entry_form_sheet.dart';

enum _Period { day, week, month }

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  _Period _period = _Period.day;
  DateTime _anchor = DualDate.dayOnly(DateTime.now());

  DateRange get _range {
    switch (_period) {
      case _Period.day:
        final from = _anchor;
        return DateRange(from, from.add(const Duration(days: 1)));
      case _Period.week:
        final start = _anchor.subtract(Duration(days: _anchor.weekday - 1));
        return DateRange(start, start.add(const Duration(days: 7)));
      case _Period.month:
        final start = DateTime(_anchor.year, _anchor.month, 1);
        return DateRange(start, DateTime(_anchor.year, _anchor.month + 1, 1));
    }
  }

  void _shift(int days) {
    setState(() {
      final step = switch (_period) {
        _Period.day => 1,
        _Period.week => 7,
        _Period.month => 0,
      };
      if (_period == _Period.month) {
        _anchor = DateTime(_anchor.year, _anchor.month + days, 1);
      } else {
        _anchor = _anchor.add(Duration(days: step * days));
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _anchor = DualDate.dayOnly(picked));
  }

  Future<void> _addEntry() async {
    final scope = ref.read(profileScopeProvider);
    if (scope.isEmpty) return;
    await showEntryForm(
      context,
      profileId: scope.first,
      allowedKinds: const [EntryKind.expense, EntryKind.income, EntryKind.profit],
      initialKind: EntryKind.expense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final language = languageForLocale(settings.locale.languageCode);
    final range = _range;
    final entriesAsync = ref.watch(entriesInRangeProvider(range));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navLedger),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: l10n.today,
            onPressed: () => setState(
              () => _anchor = DualDate.dayOnly(DateTime.now()),
            ),
            icon: const Icon(Icons.today_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEntry,
        icon: const Icon(Icons.add),
        label: Text(l10n.addExpense),
      ),
      body: Column(
        children: [
          _DateHeader(
            anchor: _anchor,
            period: _period,
            language: language,
            onPrev: () => _shift(-1),
            onNext: () => _shift(1),
            onPick: _pickDate,
            onPeriodChanged: (p) => setState(() => _period = p),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.noEntriesForPeriod,
                    action: FilledButton.icon(
                      onPressed: _addEntry,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addExpense),
                    ),
                  );
                }
                final totals = PeriodTotals.of(entries);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                  children: [
                    _TotalsRow(totals: totals),
                    const SizedBox(height: 8),
                    for (final entry in entries)
                      EntryTile(
                        entry: entry,
                        showDate: _period != _Period.day,
                        onTap: () => _editEntry(entry),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editEntry(Entry entry) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editEntry),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.delete),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'edit') {
      await showEntryForm(
        context,
        profileId: entry.profileId,
        allowedKinds: entry.kind.isPeople
            ? const [
                EntryKind.lent,
                EntryKind.borrowed,
                EntryKind.repaidByThem,
                EntryKind.repaidToThem,
              ]
            : const [
                EntryKind.expense,
                EntryKind.income,
                EntryKind.profit,
              ],
        existing: entry,
      );
    } else if (action == 'delete') {
      final confirmed = await _confirmDelete();
      if (confirmed) {
        await ref.read(entryRepositoryProvider).deleteEntry(entry.id);
      }
    }
  }

  Future<bool> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteEntryTitle),
        content: Text(l10n.deleteEntryMessage),
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

class _DateHeader extends StatelessWidget {
  const _DateHeader({
    required this.anchor,
    required this.period,
    required this.language,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
    required this.onPeriodChanged,
  });

  final DateTime anchor;
  final _Period period;
  final Language language;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;
  final ValueChanged<_Period> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final dual = DualDate(anchor);
    final primary = switch (period) {
      _Period.day => dual.bsLong(language),
      _Period.week || _Period.month => dual.bsMonthYear(language),
    };
    final secondary = switch (period) {
      _Period.day => dual.adLong,
      _Period.week || _Period.month => dual.adMonthYear,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onPrev,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: InkWell(
                  onTap: onPick,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Text(
                          primary,
                          textAlign: TextAlign.center,
                          style: context.texts.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          secondary,
                          style: context.texts.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SegmentedButton<_Period>(
            segments: [
              ButtonSegment(value: _Period.day, label: Text(l10n.today)),
              ButtonSegment(value: _Period.week, label: Text(l10n.thisWeek)),
              ButtonSegment(value: _Period.month, label: Text(l10n.thisMonth)),
            ],
            selected: {period},
            onSelectionChanged: (s) => onPeriodChanged(s.first),
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends ConsumerWidget {
  const _TotalsRow({required this.totals});

  final PeriodTotals totals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final symbol = ref.watch(settingsProvider).currencySymbol;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _TotalItem(
              label: l10n.dayTotalIncome,
              value: totals.income,
              color: context.appColors.income,
              symbol: symbol,
            ),
            _TotalItem(
              label: l10n.dayTotalExpense,
              value: totals.expense,
              color: context.appColors.expense,
              symbol: symbol,
            ),
            _TotalItem(
              label: l10n.dayTotalProfit,
              value: totals.profit,
              color: context.appColors.profit,
              symbol: symbol,
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalItem extends StatelessWidget {
  const _TotalItem({
    required this.label,
    required this.value,
    required this.color,
    required this.symbol,
  });

  final String label;
  final double value;
  final Color color;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final parts = value.toStringAsFixed(2).split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (m) => '${m[1]},',
    );
    final text = parts[1] == '00' ? whole : '$whole.${parts[1]}';
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$symbol $text',
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
