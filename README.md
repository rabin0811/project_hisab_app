# project_hisab_app

## Hisab App — Daily Karobar

A Flutter personal money tracker with a daily ledger, per-person lending/borrowing accounts, and a dashboard. Data is stored locally with Drift.

- Original location: `D:\projects\Hisab_App`
- Working copy: `D:\PROJECTS_READY\project_hisab_app`
- Stack: Flutter, Dart, Riverpod, go_router, Drift, fl_chart, Nepali utilities

## Folder layout

```text
project_hisab_app/
  app/        Flutter application
  database/   Database notes and schema reference
  docs/       Project documentation
```

## Setup and run

```powershell
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

Use `flutter devices` to choose a connected device or emulator. For a release APK:

```powershell
flutter build apk --release
```

## Verified status (2026-11-09)

- [x] Dependencies resolved with `flutter pub get`
- [x] `flutter analyze` completed with no issues
- [x] `flutter test` passed 14/14 tests
- [x] Drift code generation completed
- [ ] Release APK not built during this verification pass

## Notes and limitations

- The app is offline-first; data stays in the local Drift database.
- Nepali date/number formatting uses `nepali_utils`.
- The Flutter build output and generated files are ignored by Git.
- No backend or environment variables are required.

## Troubleshooting

- **Drift generated file missing**: run `dart run build_runner build --delete-conflicting-outputs`.
- **No devices found**: start an emulator or connect a device, then run `flutter devices`.
- **Analyzer errors after pulling changes**: run `flutter pub get` and regenerate Drift code.
- **Build cache issues**: `flutter clean` and retry.
