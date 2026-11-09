import 'package:drift/drift.dart';

import '../local/database.dart';
import '../models/enums.dart';

/// Reads profiles (Personal / Business / ...).
class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  Stream<List<Profile>> watchProfiles() {
    final query = _db.select(_db.profiles)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.watch();
  }

  Future<List<Profile>> getProfiles() => _db.select(_db.profiles).get();

  Future<int> addProfile({
    required String name,
    required ProfileType type,
  }) {
    return _db
        .into(_db.profiles)
        .insert(ProfilesCompanion.insert(name: name, type: type));
  }
}
