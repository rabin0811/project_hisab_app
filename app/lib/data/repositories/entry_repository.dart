import 'package:drift/drift.dart';

import '../local/database.dart';
import '../models/enums.dart';

/// Reads and writes daily-ledger and people entries.
class EntryRepository {
  EntryRepository(this._db);

  final AppDatabase _db;

  /// Watches entries for the given profiles, optionally restricted to a date
  /// range (`[from]` inclusive, `[to]` exclusive).
  Stream<List<Entry>> watchEntries({
    List<int>? profileIds,
    DateTime? from,
    DateTime? to,
  }) {
    final query = _db.select(_db.entries);
    if (profileIds != null && profileIds.isNotEmpty) {
      query.where((t) => t.profileId.isIn(profileIds));
    }
    if (from != null) {
      query.where((t) => t.date.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      query.where((t) => t.date.isSmallerThanValue(to));
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.date),
      (t) => OrderingTerm.desc(t.createdAt),
    ]);
    return query.watch();
  }

  Stream<List<Entry>> watchPersonEntries(int personId) {
    final query = _db.select(_db.entries)
      ..where((t) => t.personId.equals(personId))
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    return query.watch();
  }

  Future<int> addEntry({
    required int profileId,
    required EntryKind kind,
    required double amount,
    required DateTime date,
    int? accountId,
    int? personId,
    String? category,
    String? note,
  }) {
    return _db
        .into(_db.entries)
        .insert(
          EntriesCompanion.insert(
            profileId: profileId,
            kind: kind,
            amount: amount,
            date: date,
            accountId: Value(accountId),
            personId: Value(personId),
            category: Value(category),
            note: Value(note),
          ),
        );
  }

  Future<void> updateEntry(Entry entry) =>
      _db.update(_db.entries).replace(entry);

  Future<void> deleteEntry(int id) =>
      (_db.delete(_db.entries)..where((t) => t.id.equals(id))).go();
}
