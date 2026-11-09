import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/providers/app_providers.dart';
import '../../data/local/database.dart';

/// Opens the add/edit person sheet. Returns `true` when saved.
Future<bool> showPersonForm(BuildContext context, {Person? existing}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _PersonFormSheet(existing: existing),
    ),
  );
  return saved ?? false;
}

class _PersonFormSheet extends ConsumerStatefulWidget {
  const _PersonFormSheet({this.existing});

  final Person? existing;

  @override
  ConsumerState<_PersonFormSheet> createState() => _PersonFormSheetState();
}

class _PersonFormSheetState extends ConsumerState<_PersonFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _note;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
    _note = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final repo = ref.read(personRepositoryProvider);
    final name = _name.text.trim();
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();

    try {
      if (_isEditing) {
        await repo.updatePerson(
          widget.existing!.copyWith(
            name: name,
            phone: Value(phone),
            note: Value(note),
          ),
        );
      } else {
        final scope = ref.read(profileScopeProvider);
        final profileId = scope.isNotEmpty
            ? scope.first
            : (await ref.read(profileRepositoryProvider).getProfiles())
                  .first
                  .id;
        await repo.addPerson(
          profileId: profileId,
          name: name,
          phone: phone,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isEditing ? l10n.editPerson : l10n.newPerson,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.person),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? l10n.person : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: '${l10n.person} # (${l10n.optional})',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: '${l10n.note} (${l10n.optional})',
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
