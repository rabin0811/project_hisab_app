import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/entry_repository.dart';
import '../../data/repositories/person_repository.dart';
import '../../data/repositories/profile_repository.dart';

/// The single app database instance.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final entryRepositoryProvider = Provider<EntryRepository>(
  (ref) => EntryRepository(ref.watch(databaseProvider)),
);
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(databaseProvider)),
);
final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(databaseProvider)),
);
final personRepositoryProvider = Provider<PersonRepository>(
  (ref) => PersonRepository(ref.watch(databaseProvider)),
);

/// Which profile the dashboard is currently scoped to.
/// `null` means "Both" (all profiles).
class ActiveProfileNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? profileId) => state = profileId;
}

final activeProfileProvider = NotifierProvider<ActiveProfileNotifier, int?>(
  ActiveProfileNotifier.new,
);

final profilesProvider = StreamProvider<List<Profile>>(
  (ref) => ref.watch(profileRepositoryProvider).watchProfiles(),
);

final accountsProvider = StreamProvider<List<Account>>(
  (ref) => ref.watch(accountRepositoryProvider).watchAccounts(),
);

final peopleProvider = StreamProvider<List<Person>>(
  (ref) => ref.watch(personRepositoryProvider).watchPeople(),
);

/// Profile ids currently in scope. Empty while profiles are still loading.
final profileScopeProvider = Provider<List<int>>((ref) {
  final active = ref.watch(activeProfileProvider);
  if (active != null) return [active];
  final profiles = ref.watch(profilesProvider).value ?? const [];
  return [for (final p in profiles) p.id];
});

final entriesProvider = StreamProvider<List<Entry>>((ref) {
  final scope = ref.watch(profileScopeProvider);
  if (scope.isEmpty) return const Stream.empty();
  return ref.watch(entryRepositoryProvider).watchEntries(profileIds: scope);
});

/// Every entry across all profiles (used for per-account balances).
final allEntriesProvider = StreamProvider<List<Entry>>(
  (ref) => ref.watch(entryRepositoryProvider).watchEntries(),
);

/// Entries for a single person (used by the person detail screen).
final personEntriesProvider = StreamProvider.family<List<Entry>, int>(
  (ref, personId) =>
      ref.watch(entryRepositoryProvider).watchPersonEntries(personId),
);

/// Aggregate figures for the dashboard cards.
class Summary {
  const Summary({
    this.cashInHand = 0,
    this.owedToMe = 0,
    this.owedByMe = 0,
  });

  final double cashInHand;
  final double owedToMe;
  final double owedByMe;

  double get netWorth => cashInHand + owedToMe - owedByMe;
}

final summaryProvider = Provider<Summary>((ref) {
  final scope = ref.watch(profileScopeProvider);
  final accounts = ref.watch(accountsProvider).value ?? const [];
  final entries = ref.watch(entriesProvider).value ?? const [];

  final accountsInScope = accounts.where((a) => scope.contains(a.profileId));

  var cash = 0.0;
  for (final a in accountsInScope) {
    cash += a.openingBalance;
  }

  final balances = <int, double>{};
  for (final e in entries) {
    if (e.kind.isCashIn) {
      cash += e.amount;
    } else if (e.kind.isCashOut) {
      cash -= e.amount;
    }
    final personId = e.personId;
    if (personId != null) {
      final sign = e.kind.personBalanceSign;
      if (sign != 0) {
        balances[personId] = (balances[personId] ?? 0) + sign * e.amount;
      }
    }
  }

  var owedToMe = 0.0;
  var owedByMe = 0.0;
  for (final balance in balances.values) {
    if (balance > 0) {
      owedToMe += balance;
    } else {
      owedByMe += -balance;
    }
  }

  return Summary(
    cashInHand: cash,
    owedToMe: owedToMe,
    owedByMe: owedByMe,
  );
});

/// Person id -> running balance (positive = they owe me).
final personBalancesProvider = Provider<Map<int, double>>((ref) {
  final entries = ref.watch(entriesProvider).value ?? const [];
  final balances = <int, double>{};
  for (final e in entries) {
    final personId = e.personId;
    if (personId == null) continue;
    final sign = e.kind.personBalanceSign;
    if (sign == 0) continue;
    balances[personId] = (balances[personId] ?? 0) + sign * e.amount;
  }
  return balances;
});

/// An inclusive-from / exclusive-to date window used by the ledger.
@immutable
class DateRange {
  const DateRange(this.from, this.to);

  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

final entriesInRangeProvider =
    StreamProvider.family<List<Entry>, DateRange>((ref, range) {
  final scope = ref.watch(profileScopeProvider);
  if (scope.isEmpty) return const Stream.empty();
  return ref.watch(entryRepositoryProvider).watchEntries(
    profileIds: scope,
    from: range.from,
    to: range.to,
  );
});

/// Income / expense / profit totals for a set of entries.
@immutable
class PeriodTotals {
  const PeriodTotals({
    this.income = 0,
    this.expense = 0,
    this.profit = 0,
  });

  final double income;
  final double expense;
  final double profit;

  static PeriodTotals of(Iterable<Entry> entries) {
    var income = 0.0;
    var expense = 0.0;
    var profit = 0.0;
    for (final e in entries) {
      switch (e.kind) {
        case EntryKind.income:
          income += e.amount;
        case EntryKind.expense:
          expense += e.amount;
        case EntryKind.profit:
          profit += e.amount;
        default:
          break;
      }
    }
    return PeriodTotals(income: income, expense: expense, profit: profit);
  }
}

/// The current people search string.
class PeopleQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final peopleQueryProvider = NotifierProvider<PeopleQueryNotifier, String>(
  PeopleQueryNotifier.new,
);

/// People in the active profile scope, filtered by the search query.
final filteredPeopleProvider = StreamProvider<List<Person>>((ref) {
  final query = ref.watch(peopleQueryProvider);
  final scope = ref.watch(profileScopeProvider);
  return ref
      .watch(personRepositoryProvider)
      .watchPeople(query: query)
      .map((list) => [for (final p in list) if (scope.contains(p.profileId)) p]);
});

