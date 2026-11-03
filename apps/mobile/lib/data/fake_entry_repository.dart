import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// The KT1 implementation of [EntryRepository]: everyone's entries in memory, with a delay, and two switches the
/// debug buttons use to show the failure and the empty state of a screen.
///
/// It holds the entries of all users, because it plays the server: rules over other users' data (R4) are decided
/// here, with the same domain functions the server will use.
final class FakeEntryRepository implements EntryRepository {
  FakeEntryRepository({required List<Entry> seed, this.latency = const Duration(milliseconds: 600)})
    : _entries = [...seed];

  final List<Entry> _entries;

  /// The delay of every request, like a network. Tests use `Duration.zero`.
  final Duration latency;

  /// How many of the next requests fail with [RepositoryException] ("Simuliraj grešku").
  int failingRequests = 0;

  /// How many of the next loads return an empty list ("Prazan odgovor").
  int emptyResponses = 0;

  @override
  Future<List<Entry>> entriesOf(UserId owner) async {
    await _request();
    if (emptyResponses > 0) {
      emptyResponses--;
      return const [];
    }
    final mine = [
      for (final entry in _entries)
        if (entry.owner == owner) entry,
    ];
    return mine..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Entry?> find(EntryId id) async {
    await _request();
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  Future<Result<List<Entry>>> submitLink(VideoLink link, {required UserId owner}) {
    throw UnimplementedError('submitLink comes with the analysis (step 8b)');
  }

  @override
  Future<Entry> save(Entry entry) async {
    await _request();
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      _entries.add(entry);
    } else {
      _entries[index] = entry;
    }
    return entry;
  }

  @override
  Future<void> delete(EntryId id) async {
    await _request();
    _entries.removeWhere((e) => e.id == id);
  }

  /// Waits like a network, then fails if a debug button asked for it.
  Future<void> _request() async {
    await Future<void>.delayed(latency);
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('simulated failure (debug button)');
    }
  }
}
