import 'package:drift/drift.dart';

import '../local/database.dart';
import '../models/enums.dart';

/// Reads and writes money accounts (bank / wallet / cash).
class AccountRepository {
  AccountRepository(this._db);

  final AppDatabase _db;

  Stream<List<Account>> watchAccounts() {
    final query = _db.select(_db.accounts)
      ..where((t) => t.archived.equals(false))
      ..orderBy([
        (t) => OrderingTerm.asc(t.type),
        (t) => OrderingTerm.asc(t.name),
      ]);
    return query.watch();
  }

  Future<List<Account>> getAccounts() =>
      (_db.select(_db.accounts)..where((t) => t.archived.equals(false))).get();

  Future<int> addAccount({
    required int profileId,
    required String name,
    required AccountType type,
    double openingBalance = 0,
  }) {
    return _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(
            profileId: profileId,
            name: name,
            type: type,
            openingBalance: Value(openingBalance),
          ),
        );
  }

  Future<void> updateAccount(Account account) =>
      _db.update(_db.accounts).replace(account);

  Future<void> deleteAccount(int id) =>
      (_db.delete(_db.accounts)..where((t) => t.id.equals(id))).go();
}
