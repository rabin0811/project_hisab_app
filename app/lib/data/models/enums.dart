/// Core domain enums for the app.
///
/// These are stored in the database as their index via drift's `intEnum`.
/// If you reorder them, add a migration.
library;

/// A profile scopes accounts, people and entries (e.g. Personal, Business).
enum ProfileType { personal, business }

/// The kind of money account.
enum AccountType { bank, wallet, cash }

/// Every entry in the app shares a single table and one of these kinds.
///
/// Daily-ledger kinds: [income], [expense], [profit].
/// People-ledger kinds: [lent], [borrowed], [repaidByThem], [repaidToThem].
enum EntryKind {
  /// Money earned (salary, sales, ...). Cash in.
  income,

  /// Money spent. Cash out.
  expense,

  /// Business profit booked separately from income. Cash in.
  profit,

  /// I lent money to a person. Cash out; they now owe me.
  lent,

  /// I borrowed money from a person. Cash in; I now owe them.
  borrowed,

  /// A person gave me money back. Cash in; reduces what they owe me.
  repaidByThem,

  /// I gave a person money back. Cash out; reduces what I owe them.
  repaidToThem,
}

extension EntryKindX on EntryKind {
  /// True for kinds that appear in the daily ledger.
  bool get isLedger =>
      this == EntryKind.income ||
      this == EntryKind.expense ||
      this == EntryKind.profit;

  /// True for kinds that belong to a person's ledger.
  bool get isPeople => !isLedger;

  /// Whether this kind moves money into an account (increases cash).
  bool get isCashIn =>
      this == EntryKind.income ||
      this == EntryKind.profit ||
      this == EntryKind.borrowed ||
      this == EntryKind.repaidByThem;

  /// Whether this kind moves money out of an account (decreases cash).
  bool get isCashOut =>
      this == EntryKind.expense ||
      this == EntryKind.lent ||
      this == EntryKind.repaidToThem;

  /// Sign applied to a person's running balance (positive = they owe me).
  int get personBalanceSign => switch (this) {
    EntryKind.lent => 1,
    EntryKind.repaidToThem => 1,
    EntryKind.borrowed => -1,
    EntryKind.repaidByThem => -1,
    EntryKind.income || EntryKind.expense || EntryKind.profit => 0,
  };
}
