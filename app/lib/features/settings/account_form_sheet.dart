import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/account_style.dart';
import '../../data/local/database.dart';
import '../../data/models/enums.dart';

/// Opens the add/edit account sheet. Pass [profileId] to pre-select a profile
/// when creating, or [existing] to edit.
///
/// Returns `true` when saved.
Future<bool> showAccountForm(
  BuildContext context, {
  int? profileId,
  Account? existing,
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
      child: _AccountFormSheet(profileId: profileId, existing: existing),
    ),
  );
  return saved ?? false;
}

class _AccountFormSheet extends ConsumerStatefulWidget {
  const _AccountFormSheet({this.profileId, this.existing});

  final int? profileId;
  final Account? existing;

  @override
  ConsumerState<_AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends ConsumerState<_AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _opening;

  late AccountType _type;
  int? _profileId;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type ?? AccountType.wallet;
    _name = TextEditingController(text: existing?.name ?? '');
    _opening = TextEditingController(
      text: existing == null || existing.openingBalance == 0
          ? ''
          : _trimNumber(existing.openingBalance),
    );
    _profileId = existing?.profileId ?? widget.profileId;
    // Default to the first profile so the user isn't forced to pick one when
    // there is no obvious target (e.g. "Both" scope).
    if (_profileId == null) {
      final profiles = ref.read(profilesProvider).value;
      if (profiles != null && profiles.isNotEmpty) {
        _profileId = profiles.first.id;
      }
    }
  }

  static String _trimNumber(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = _profileId;
    if (profileId == null) return;

    setState(() => _saving = true);
    final repo = ref.read(accountRepositoryProvider);
    final name = _name.text.trim();
    final opening = double.tryParse(_opening.text.trim()) ?? 0;

    try {
      if (_isEditing) {
        await repo.updateAccount(
          widget.existing!.copyWith(
            name: name,
            type: _type,
            openingBalance: opening,
          ),
        );
      } else {
        await repo.addAccount(
          profileId: profileId,
          name: name,
          type: _type,
          openingBalance: opening,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Cash is a single account per profile (per the spec).
  bool get _cashAlreadyExists {
    if (_type != AccountType.cash || _profileId == null) return false;
    final accounts = ref.read(accountsProvider).value ?? const <Account>[];
    return accounts.any(
      (a) =>
          a.profileId == _profileId &&
          a.type == AccountType.cash &&
          a.id != widget.existing?.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profiles = ref.watch(profilesProvider).value ?? const <Profile>[];
    final presets = kAccountPresets[_type] ?? const [];
    final blocked = _cashAlreadyExists;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEditing ? l10n.editAccount : l10n.newAccount,
              style: context.texts.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),

            // Account type.
            Text(
              l10n.accountType,
              style: context.texts.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<AccountType>(
              showSelectedIcon: false,
              segments: [
                for (final type in AccountType.values)
                  ButtonSegment(
                    value: type,
                    icon: Icon(type.icon, size: 18),
                    label: Text(type.label(l10n)),
                  ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),

            // Profile (only when creating).
            if (!_isEditing && profiles.length > 1) ...[
              DropdownButtonFormField<int>(
                initialValue: _profileId,
                decoration: InputDecoration(labelText: l10n.selectProfile),
                items: [
                  for (final p in profiles)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => _profileId = v),
                validator: (v) => v == null ? l10n.selectProfile : null,
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _name,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.accountName),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.accountName : null,
            ),

            if (presets.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                l10n.quickAdd,
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final preset in presets)
                    ActionChip(
                      label: Text(preset),
                      onPressed: () => setState(() => _name.text = preset),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            TextFormField(
              controller: _opening,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: '${l10n.openingBalance} (${l10n.optional})',
              ),
            ),

            if (blocked) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: context.appColors.negative,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.cashAccountExists,
                      style: context.texts.bodySmall?.copyWith(
                        color: context.appColors.negative,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
                    onPressed: (_saving || blocked) ? null : _save,
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
