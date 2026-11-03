import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// The simplest adapter of [ReviewQueueRepository], for tests: a list in memory, no delay.
final class InMemoryReviewQueue implements ReviewQueueRepository {
  InMemoryReviewQueue([List<Entry> initial = const []]) : _entries = [...initial];

  final List<Entry> _entries;

  /// When true, the next call throws, like a lost connection.
  bool failNextCall = false;

  @override
  Future<List<ReviewItem>> pending() async {
    _failIfAsked();
    return [
      for (final entry in _entries)
        if (ReviewItem.of(entry, catalog: const []) case final item?) item,
    ];
  }

  @override
  Future<Entry?> find(EntryId id) async {
    _failIfAsked();
    return _entries.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<Entry> decide(Entry entry) async {
    _failIfAsked();
    _entries[_entries.indexWhere((e) => e.id == entry.id)] = entry;
    return entry;
  }

  void _failIfAsked() {
    if (!failNextCall) return;
    failNextCall = false;
    throw const RepositoryException('simulated failure');
  }
}
