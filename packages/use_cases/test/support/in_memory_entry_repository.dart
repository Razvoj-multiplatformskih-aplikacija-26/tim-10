import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// The simplest adapter of [EntryRepository], for tests: a list in memory, no delay, no rules of its own.
///
/// It counts how often a link was sent, so a test can prove that a use case did not send it.
final class InMemoryEntryRepository implements EntryRepository {
  InMemoryEntryRepository([List<Entry> initial = const []]) : _entries = [...initial];

  final List<Entry> _entries;

  /// The answer to the next [submitLink]; by default the link becomes one queued entry.
  Result<List<Entry>>? nextSubmitResult;

  /// When true, the next call throws, like a lost connection.
  bool failNextCall = false;

  int submitCount = 0;

  @override
  Future<List<Entry>> entriesOf(UserId owner) async {
    _failIfAsked();
    return [
      for (final entry in _entries)
        if (entry.owner == owner) entry,
    ];
  }

  @override
  Future<Entry?> find(EntryId id) async {
    _failIfAsked();
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  Future<Result<List<Entry>>> submitLink(VideoLink link, {required UserId owner}) async {
    _failIfAsked();
    submitCount++;
    return nextSubmitResult ?? Success([_queued(link, owner)]);
  }

  @override
  Future<Entry> save(Entry entry) async {
    _failIfAsked();
    _entries
      ..removeWhere((e) => e.id == entry.id)
      ..add(entry);
    return entry;
  }

  @override
  Future<void> delete(EntryId id) async {
    _failIfAsked();
    _entries.removeWhere((e) => e.id == id);
  }

  Entry _queued(VideoLink link, UserId owner) {
    final at = DateTime.utc(2026, 11, 4, 12);
    return Entry(
      id: EntryId('new-$submitCount'),
      owner: owner,
      source: FromVideo(link: link),
      status: Queued(at: at),
      createdAt: at,
      analysisRequests: [at],
    );
  }

  void _failIfAsked() {
    if (!failNextCall) return;
    failNextCall = false;
    throw const RepositoryException('simulated failure');
  }
}
