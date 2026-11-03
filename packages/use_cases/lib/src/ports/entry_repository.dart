import 'package:domain/domain.dart';

/// Port: what the user's screens need from the entries, not how they get them.
///
/// Implemented in the apps: a fake in memory for KT1, an HTTP client of the server from KT2. The choice is made in
/// one place, `dependencies.dart`. Every method throws `RepositoryException` when the data cannot be reached; a rule
/// that fails is returned as a `Failure(DomainError)` instead.
abstract interface class EntryRepository {
  /// All entries of [owner], newest first.
  Future<List<Entry>> entriesOf(UserId owner);

  Future<Entry?> find(EntryId id);

  /// Sends a new link. The implementation (the server in KT2) makes the final decision over everyone's data:
  /// the daily limit (R2) and the existing analysis (R4). A list, because R4 gives all items of the video at once.
  Future<Result<List<Entry>>> submitLink(VideoLink link, {required UserId owner});

  /// Stores an entry changed by a domain action (`saveEntry`, `proposeEntry`, ...).
  Future<Entry> save(Entry entry);

  Future<void> delete(EntryId id);
}
