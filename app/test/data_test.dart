import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_app/core/providers/app_providers.dart';
import 'package:hisab_app/data/local/database.dart';
import 'package:hisab_app/data/models/enums.dart';
import 'package:hisab_app/data/repositories/account_repository.dart';
import 'package:hisab_app/data/repositories/entry_repository.dart';
import 'package:hisab_app/data/repositories/person_repository.dart';
import 'package:hisab_app/data/repositories/profile_repository.dart';

void main() {
  late AppDatabase db;
  late ProfileRepository profiles;
  late AccountRepository accounts;
  late PersonRepository people;
  late EntryRepository entries;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    profiles = ProfileRepository(db);
    accounts = AccountRepository(db);
    people = PersonRepository(db);
    entries = EntryRepository(db);
  });

  tearDown(() => db.close());

  test('seeds two profiles and a cash account each', () async {
    final all = await profiles.getProfiles();
    expect(all.map((p) => p.name), containsAll(['Personal', 'Business']));

    final accts = await accounts.getAccounts();
    expect(accts, hasLength(2));
    expect(accts.every((a) => a.type == AccountType.cash), isTrue);
  });

  test('adds ledger entries and reads them back in range', () async {
    final profile = (await profiles.getProfiles()).first;
    final account = (await accounts.getAccounts())
        .firstWhere((a) => a.profileId == profile.id);

    final today = DateTime.now();
    await entries.addEntry(
      profileId: profile.id,
      kind: EntryKind.income,
      amount: 1000,
      date: today,
      accountId: account.id,
      category: 'Salary',
    );
    await entries.addEntry(
      profileId: profile.id,
      kind: EntryKind.expense,
      amount: 250,
      date: today,
      accountId: account.id,
    );

    final day = DateTime(today.year, today.month, today.day);
    final inRange = await entries
        .watchEntries(
          profileIds: [profile.id],
          from: day,
          to: day.add(const Duration(days: 1)),
        )
        .first;

    expect(inRange, hasLength(2));
    final totals = PeriodTotals.of(inRange);
    expect(totals.income, 1000);
    expect(totals.expense, 250);
  });

  test('range query excludes entries outside the window', () async {
    final profile = (await profiles.getProfiles()).first;
    await entries.addEntry(
      profileId: profile.id,
      kind: EntryKind.expense,
      amount: 50,
      date: DateTime(2020, 1, 1),
    );

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final inRange = await entries
        .watchEntries(
          profileIds: [profile.id],
          from: todayOnly,
          to: todayOnly.add(const Duration(days: 1)),
        )
        .first;

    expect(inRange, isEmpty);
  });

  test('people balance: lend, borrow and repayments net correctly', () async {
    final profile = (await profiles.getProfiles()).first;
    final personId = await people.addPerson(
      profileId: profile.id,
      name: 'Ram',
    );

    await entries.addEntry(
      profileId: profile.id,
      kind: EntryKind.lent,
      amount: 500,
      date: DateTime.now(),
      personId: personId,
    );
    await entries.addEntry(
      profileId: profile.id,
      kind: EntryKind.repaidByThem,
      amount: 200,
      date: DateTime.now(),
      personId: personId,
    );

    final history = await entries.watchPersonEntries(personId).first;
    expect(history, hasLength(2));
    // They still owe 300.
    expect(people.balanceFrom(history), 300);

    await entries.addEntry(
      profileId: profile.id,
      kind: EntryKind.borrowed,
      amount: 100,
      date: DateTime.now(),
      personId: personId,
    );
    final after = await entries.watchPersonEntries(personId).first;
    // 500 - 200 - 100 = 200 owed to me.
    expect(people.balanceFrom(after), 200);
  });

  test('deleting a person cascades their entries', () async {
    final profile = (await profiles.getProfiles()).first;
    final personId = await people.addPerson(profileId: profile.id, name: 'Sita');
    await entries.addEntry(
      profileId: profile.id,
      kind: EntryKind.lent,
      amount: 100,
      date: DateTime.now(),
      personId: personId,
    );

    await people.deletePerson(personId);

    final history = await entries.watchPersonEntries(personId).first;
    expect(history, isEmpty);
  });

  test('supports multiple wallets and banks per profile', () async {
    final profile = (await profiles.getProfiles()).first;
    await accounts.addAccount(
      profileId: profile.id,
      name: 'eSewa',
      type: AccountType.wallet,
    );
    await accounts.addAccount(
      profileId: profile.id,
      name: 'Khalti',
      type: AccountType.wallet,
    );
    await accounts.addAccount(
      profileId: profile.id,
      name: 'Nabil Bank',
      type: AccountType.bank,
    );

    final all = await accounts.getAccounts();
    expect(all.where((a) => a.type == AccountType.wallet).length, 2);
    expect(all.where((a) => a.type == AccountType.bank).length, 1);
    // The seed creates one cash account per profile.
    expect(all.where((a) => a.type == AccountType.cash).length, 2);
  });

  test('opening balance is stored and can be updated', () async {
    final profile = (await profiles.getProfiles()).first;
    final id = await accounts.addAccount(
      profileId: profile.id,
      name: 'eSewa',
      type: AccountType.wallet,
      openingBalance: 1500,
    );

    var account = (await accounts.getAccounts()).firstWhere((a) => a.id == id);
    expect(account.openingBalance, 1500);

    await accounts.updateAccount(account.copyWith(openingBalance: 2000));
    account = (await accounts.getAccounts()).firstWhere((a) => a.id == id);
    expect(account.openingBalance, 2000);
  });

  test('deleting an account keeps its entries but unlinks them', () async {
    final profile = (await profiles.getProfiles()).first;
    final accountId = await accounts.addAccount(
      profileId: profile.id,
      name: 'eSewa',
      type: AccountType.wallet,
    );
    final entryId = await entries.addEntry(
      profileId: profile.id,
      kind: EntryKind.expense,
      amount: 100,
      date: DateTime.now(),
      accountId: accountId,
    );

    await accounts.deleteAccount(accountId);

    final all = await entries.watchEntries().first;
    final remaining = all.firstWhere((e) => e.id == entryId);
    expect(remaining.accountId, isNull);
  });
}
