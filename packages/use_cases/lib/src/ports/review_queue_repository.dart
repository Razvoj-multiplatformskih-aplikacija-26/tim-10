import 'package:domain/domain.dart';

/// Port: what the editor's screens need from the proposals.
///
/// Implemented in the backoffice: a fake in memory for KT1, an HTTP client of the server from KT2. Every method
/// throws `RepositoryException` when the data cannot be reached.
abstract interface class ReviewQueueRepository {
  /// The proposals waiting for a decision, oldest first, each with its possible duplicates (R5).
  Future<List<ReviewItem>> pending();

  Future<Entry?> find(EntryId id);

  /// Stores an entry changed by `publishEntry` or `rejectEntry`.
  Future<Entry> decide(Entry entry);
}
