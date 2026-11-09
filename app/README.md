# Daily Karobar

A personal money tracker for Nepal: a daily income/expense/profit ledger, a
per-person lending & borrowing ledger, and a dashboard — with **dual BS + AD
dates**, **English/Nepali**, and **light/dark** theming.

Local-first: all data is stored on-device (SQLite via Drift). Cloud sign-in /
sync is planned and currently stubbed in Settings.

## Features

- **Dashboard** — cash in hand, net worth, owed-to-me / owed-by-me, a chart
  carousel (7-day income vs expense, expenses by category, 14-day cash
  balance), quick actions and recent activity. Scope by Personal / Business / Both.
- **Daily Ledger** — day / week / month views with BS + AD headers, income,
  expense and profit entries, per-period totals, add/edit/delete.
- **People Ledger** — contacts with a running balance (they owe me / I owe
  them / settled), plus lend, borrow and repayment transactions.
- **Accounts** — manage multiple banks, digital wallets (eSewa, Khalti, IME Pay,
  Fonepay, …) and a cash account per profile, each with an opening balance and
  a live current balance. Quick-add presets for common Nepali providers.
- **Settings** — language (English / Nepali), theme (System / Light / Dark),
  accent color, profiles & accounts, and a sign-in placeholder.
- **Quick theme toggle** — a light/dark switch in the top bar of the Home,
  Ledger, People and Settings screens.

## Tech stack

| Concern            | Choice                         |
| ------------------ | ------------------------------ |
| UI                 | Flutter (Material 3)           |
| State management   | Riverpod 3                     |
| Local database     | Drift (SQLite) via `drift_flutter` |
| Routing            | go_router (stateful shell)     |
| Charts             | fl_chart                       |
| Dates (BS ↔ AD)    | `nepali_utils`                 |
| i18n               | Flutter gen-l10n (ARB)         |
| Preferences        | `shared_preferences`           |

## Architecture

```
lib/
  main.dart                     # boot: load prefs, override provider, run app
  app/                          # MaterialApp, router, bottom-nav shell
  core/
    dates/dual_date.dart        # BS + AD formatting helpers
    l10n/                       # ARB files + generated AppLocalizations
    providers/                  # settings + app data providers
    theme/app_theme.dart        # theme + AppColors semantic tokens
    utils/                      # money formatting, entry-kind & account styling
  data/
    local/database.dart         # Drift tables + AppDatabase (+ .g.dart)
    models/enums.dart           # ProfileType / AccountType / EntryKind
    repositories/               # per-aggregate data access
  features/
    splash/ dashboard/ ledger/ people/ settings/
  widgets/                      # shared UI (amount text, summary card, ...)
```

### Data model

- **profiles** — Personal / Business (scopes everything).
- **accounts** — bank / wallet / cash, with an opening balance, per profile.
- **people** — contacts for lending/borrowing.
- **entries** — one table for every money movement, typed by `EntryKind`:
  `income`, `expense`, `profit`, `lent`, `borrowed`, `repaidByThem`,
  `repaidToThem`.

A person's balance is `Σ sign(kind) × amount` (positive = they owe me):
`lent` and `repaidToThem` are positive; `borrowed` and `repaidByThem` are
negative.

### Theming

Widgets never hardcode data colors. Semantic colors (income, expense, profit,
positive, negative, account types) live in the `AppColors` `ThemeExtension`,
with separate light and dark variants, and the accent is a `ColorScheme` seed.

The theme mode (System / Light / Dark) is set in Settings, and a quick light/dark
toggle is available in the top bars. When the mode is *System*, the first tap on
the toggle switches to the opposite of the platform's current brightness, so the
change is always visible.

## Getting started

```bash
flutter pub get
dart run build_runner build          # generate Drift code
flutter gen-l10n                     # generate localizations
flutter run
```

### Useful commands

```bash
flutter analyze
flutter test
flutter build apk --debug
```

## Notes

- **Android builds:** `android/gradle.properties` sets `kotlin.incremental=false`
  because incremental Kotlin caching has been flaky on Windows (file-lock errors
  while closing caches).
- **BS dates:** the Bikram Sambat calendar is not a fixed offset; conversion is
  delegated to `nepali_utils`.
- The first launch seeds two profiles (Personal, Business) with a Cash account
  each so the app is immediately usable.

## Roadmap

- Sign-in and cloud sync/backup.
- Custom budgets and recurring entries.
- Full BS date picker (currently the picker is Gregorian with BS shown alongside).
- CSV/PDF export.
