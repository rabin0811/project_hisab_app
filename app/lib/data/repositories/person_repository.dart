import 'package:drift/drift.dart';

import '../local/database.dart';
import '../models/enums.dart';

/// Reads and writes people and computes their running balances.
class PersonRepository {
  PersonRepository(this._db);

  final AppDatabase _db;

  Stream<List<Person>> watchPeople({String query = ''}) {
    final select = _db.select(_db.people);
    if (query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      select.where((t) => t.name.like(like));
    }
    select.orderBy([(t) => OrderingTerm.asc(t.name)]);
    return select.watch();
  }

  Future<int> addPerson({
    required int profileId,
    required String name,
    String? phone,
    String? note,
  }) {
    return _db
        .into(_db.people)
        .insert(
          PeopleCompanion.insert(
            profileId: profileId,
            name: name,
            phone: Value(phone),
            note: Value(note),
          ),
        );
  }

  Future<void> updatePerson(Person person) =>
      _db.update(_db.people).replace(person);

  Future<void> deletePerson(int id) =>
      (_db.delete(_db.people)..where((t) => t.id.equals(id))).go();

  /// Sum of `sign * amount` across a person's entries.
  /// Positive => they owe me; negative => I owe them.
  double balanceFrom(List<Entry> entries) {
    var total = 0.0;
    for (final e in entries) {
      total += e.kind.personBalanceSign * e.amount;
    }
    return total;
  }
}
