import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../core/dates/dual_date.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/account_style.dart';
import '../../core/utils/entry_kind_style.dart';
import '../../data/local/database.dart';
import '../../data/models/enums.dart';

/// Opens the add/edit form as a modal bottom sheet.
///
/// Returns `true` when an entry was saved.
Future<bool> showEntryForm(
  BuildContext context, {
  required int profileId,
  required List<EntryKind> allowedKinds,
  EntryKind? initialKind,
  int? personId,
  String? personName,
  Entry? existing,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _EntryFormSheet(
        profileId: profileId,
        allowedKinds: allowedKinds,
        initialKind: initialKind,
        personId: personId,
        personName: personName,
        existing: existing,
      ),
    ),
  );
  return saved ?? false;
}

class _EntryFormSheet extends ConsumerStatefulWidget {
  const _EntryFormSheet({
    required this.profileId,
    required this.allowedKinds,
    this.initialKind,
    this.personId,
    this.personName,
    this.existing,
  });

  final int profileId;
  final List<EntryKind> allowedKinds;
  final EntryKind? initialKind;
  final int? personId;
  final String? personName;
  final Entry? existing;

  @override
  ConsumerState<_EntryFormSheet> createState() => _EntryFormSheetState();
}

class _EntryFormSheetState extends ConsumerState<_EntryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _category;
  late final TextEditingController _note;

  late EntryKind _kind;
  int? _accountId;
  late DateTime _date;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;
  bool get _isPeople => _kind.isPeople;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _kind = existing?.kind ?? widget.initialKind ?? widget.allowedKinds.first;
    _amount = TextEditingController(
      text: existing == null ? '' : _trimNumber(existing.amount),
    );
    _category = TextEditingController(text: existing?.category ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _accountId = existing?.accountId;
    _date = existing?.date ?? DualDate.dayOnly(DateTime.now());
  }

  static String _trimNumber(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = DualDate.dayOnly(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final amount = double.parse(_amount.text.trim());
    final repo = ref.read(entryRepositoryProvider);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final category =
        (!_isPeople && _category.text.trim().isNotEmpty)
        ? _category.text.trim()
        : null;

    try {
      if (_isEditing) {
        final e = widget.existing!;
        await repo.updateEntry(
          e.copyWith(
            kind: _kind,
            amount: amount,
            date: _date,
            accountId: Value(_accountId),
            category: Value(category),
            note: Value(note),
          ),
        );
      } else {
        await repo.addEntry(
          profileId: widget.profileId,
          kind: _kind,
          amount: amount,
          date: _date,
          accountId: _accountId,
          personId: widget.personId,
          category: category,
          note: note,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final language = languageForLocale(settings.locale.languageCode);
    final accounts =
        (ref.watch(accountsProvider).value ?? const <Account>[])
            .where((a) => a.profileId == widget.profileId)
            .toList();

    if (_accountId == null && accounts.isNotEmpty) {
      _accountId = accounts.first.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEditing ? l10n.editEntry : l10n.newEntry,
              style: context.texts.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.personName != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.personName!,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Kind selector.
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kind in widget.allowedKinds)
                  ChoiceChip(
                    selected: _kind == kind,
                    avatar: Icon(kind.icon, size: 18),
                    label: Text(kind.label(l10n)),
                    onSelected: (_) => setState(() => _kind = kind),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amount,
              autofocus: !_isEditing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.amount,
                prefixText: '${settings.currencySymbol} ',
              ),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').trim());
                if (parsed == null || parsed <= 0) return l10n.amount;
                return null;
              },
            ),
            const SizedBox(height: 12),

            if (!_isPeople)
              TextFormField(
                controller: _category,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: '${l10n.category} (${l10n.optional})',
                ),
              ),
            if (!_isPeople) const SizedBox(height: 12),

            if (accounts.isNotEmpty) ...[
              DropdownButtonFormField<int>(
                initialValue: _accountId,
                decoration: InputDecoration(labelText: l10n.account),
                items: [
                  for (final a in accounts)
                    DropdownMenuItem(
                      value: a.id,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            a.type.icon,
                            size: 18,
                            color: a.type.color(context),
                          ),
                          const SizedBox(width: 8),
                          Text(a.name),
                        ],
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _accountId = v),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: '${l10n.note} (${l10n.optional})',
              ),
            ),
            const SizedBox(height: 12),

            // Dual date field.
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.date,
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  '${DualDate(_date).adLong}  ·  ${DualDate(_date).bsLong(language)}',
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
