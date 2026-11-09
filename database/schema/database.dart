import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/enums.dart';

part 'database.g.dart';

/// A profile groups accounts, people and entries (Personal / Business / ...).
@DataClassName('Profile')
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  IntColumn get type => intEnum<ProfileType>()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A money account. Multiple banks/wallets per profile, a single cash account.
@DataClassName('Account')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 64)();
  IntColumn get type => intEnum<AccountType>()();
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A person with whom money is lent/borrowed.
@DataClassName('Person')
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 96)();
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// A single money movement: ledger entry or people-ledger transaction.
@DataClassName('Entry')
class Entries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get profileId =>
      integer().references(Profiles, #id, onDelete: KeyAction.cascade)();
  IntColumn get accountId => integer()
      .nullable()
      .references(Accounts, #id, onDelete: KeyAction.setNull)();
  IntColumn get personId =>
      integer().nullable().references(People, #id, onDelete: KeyAction.cascade)();
  IntColumn get kind => intEnum<EntryKind>()();
  RealColumn get amount => real()();
  TextColumn get category => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();

  /// When the row was created (used as a tie-breaker when ordering).
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Profiles, Accounts, People, Entries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'daily_karobar'));

  /// Used by tests with an in-memory executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaults();
    },
  );

  /// Seeds the two default profiles with a cash account each, so the app is
  /// immediately usable on first launch.
  Future<void> _seedDefaults() async {
    final personalId = await into(profiles).insert(
      ProfilesCompanion.insert(name: 'Personal', type: ProfileType.personal),
    );
    final businessId = await into(profiles).insert(
      ProfilesCompanion.insert(name: 'Business', type: ProfileType.business),
    );
    await into(accounts).insert(
      AccountsCompanion.insert(
        profileId: personalId,
        name: 'Cash',
        type: AccountType.cash,
      ),
    );
    await into(accounts).insert(
      AccountsCompanion.insert(
        profileId: businessId,
        name: 'Cash',
        type: AccountType.cash,
      ),
    );
  }
}
