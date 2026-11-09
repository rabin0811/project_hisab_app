# Database

The app uses a local Drift/SQLite database.

- Live schema: `app/lib/data/local/database.dart`
- Reference copy: `database/schema/database.dart`
- The database file is created on the device at runtime and is not committed.

If the schema changes, update the live file in `app/` first, then refresh this reference copy.
