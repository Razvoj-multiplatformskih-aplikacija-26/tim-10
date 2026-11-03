import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// The KT1 implementation of [ReviewQueueRepository]: the proposals and the catalog in memory, with a delay, and two
/// counters the debug buttons use to show the failure and the empty state of the screen.
///
/// It plays the server: possible duplicates (R5) are found here, with the same domain function the server will use.
final class FakeReviewQueue implements ReviewQueueRepository {
  FakeReviewQueue({required List<Entry> seed, this.latency = const Duration(milliseconds: 600)}) : _entries = [...seed];

  final List<Entry> _entries;

  /// The delay of every request, like a network. Tests use `Duration.zero`.
  final Duration latency;

  /// How many of the next requests fail with [RepositoryException] ("Simuliraj grešku").
  int failingRequests = 0;

  /// How many of the next loads return an empty list ("Prazan odgovor").
  int emptyResponses = 0;

  @override
  Future<List<ReviewItem>> pending() async {
    await _request();
    if (emptyResponses > 0) {
      emptyResponses--;
      return const [];
    }
    final catalog = [
      for (final entry in _entries)
        if (entry.status is Published) entry,
    ];
    final items = [for (final entry in _entries) ?ReviewItem.of(entry, catalog: catalog)];
    return items..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  }

  @override
  Future<Entry?> find(EntryId id) async {
    await _request();
    return _entries.where((entry) => entry.id == id).firstOrNull;
  }

  @override
  Future<Entry> decide(Entry entry) async {
    await _request();
    _entries[_entries.indexWhere((e) => e.id == entry.id)] = entry;
    return entry;
  }

  Future<void> _request() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('Simulated failure of the fake repository');
    }
  }
}
