import 'dart:async';

import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

/// The KT1 implementation of [EntryRepository]: everyone's entries in memory, with a delay, and two switches the
/// debug buttons use to show the failure and the empty state of a screen.
///
/// It holds the entries of all users, because it plays the server: rules over other users' data (R4) are decided
/// here, with the same domain functions the server will use.
final class FakeEntryRepository implements EntryRepository {
  FakeEntryRepository({
    required List<Entry> seed,
    required this.clock,
    required this.analyzer,
    this.latency = const Duration(milliseconds: 600),
  }) : _entries = [...seed];

  final List<Entry> _entries;

  final Clock clock;

  /// Plays the AI behind the server.
  final VideoAnalyzer analyzer;

  /// The repository gives ids to new entries, as the server will; the domain never invents them.
  int _lastId = 0;

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
    return _find(id);
  }

  /// What the server will do with a new link, with the same domain functions:
  /// 1. R2: the daily limit, over the user's entries; every link counts, a copy too;
  /// 2. R4: if anyone already has the analysis of this video, all its items are copied at once, for review;
  /// 3. otherwise the link waits in the queue and the analysis runs in the background.
  @override
  Future<Result<List<Entry>>> submitLink(VideoLink link, {required UserId owner}) async {
    await _request();
    final now = clock.now();
    final mine = [
      for (final entry in _entries)
        if (entry.owner == owner) entry,
    ];
    if (checkDailyLimit(mine, now: now) case Failure(:final error)) return Failure(error);

    final queued = Entry(
      id: _newId(),
      owner: owner,
      source: FromVideo(link: link),
      status: Queued(at: now),
      createdAt: now,
      analysisRequests: [now],
    );

    final existing = existingAnalysisFor(link, _entries);
    if (existing != null) {
      final copies = entriesFromAnalysis(queued, existing, now: now, newId: (_) => _newId()).valueOrNull!;
      _entries.addAll(copies);
      return Success(copies);
    }

    _entries.add(queued);
    unawaited(_analyze(queued.id));
    return Success([queued]);
  }

  /// Stores an entry. An entry stored back in `Queued` is a retry ("Pokušaj ponovo"), so its analysis starts again.
  @override
  Future<Entry> save(Entry entry) async {
    await _request();
    _replace(entry);
    if (entry.status is Queued) unawaited(_analyze(entry.id));
    return entry;
  }

  @override
  Future<void> delete(EntryId id) async {
    await _request();
    _entries.removeWhere((e) => e.id == id);
  }

  /// The analysis in the background: `Queued`, after a while `Analyzing`, then the items of the video for review
  /// (one entry per item) or `AnalysisFailed` with the reason. The list shows the change on its next load.
  Future<void> _analyze(EntryId id) async {
    await Future<void>.delayed(latency);
    final waiting = _find(id);
    if (waiting == null || waiting.status is! Queued) return;
    final source = waiting.source;
    if (source is! FromVideo) return;

    final analyzing = waiting.copyWith(status: Analyzing(startedAt: clock.now()));
    _replace(analyzing);

    final outcome = await analyzer.analyze(source.link);
    final now = clock.now();
    switch (outcome) {
      case AnalysisSucceeded(:final result):
        final items = entriesFromAnalysis(analyzing, result, now: now, newId: (_) => _newId()).valueOrNull!;
        _entries.removeWhere((e) => e.id == id);
        _entries.addAll(items);
      case AnalysisFailedWith(:final reason):
        _replace(
          analyzing.copyWith(
            status: AnalysisFailed(reason: reason, at: now),
          ),
        );
    }
  }

  Entry? _find(EntryId id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  void _replace(Entry entry) {
    final index = _entries.indexWhere((e) => e.id == entry.id);
    if (index == -1) {
      _entries.add(entry);
    } else {
      _entries[index] = entry;
    }
  }

  EntryId _newId() => EntryId('e-new-${++_lastId}');

  /// Waits like a network, then fails if a debug button asked for it.
  Future<void> _request() async {
    await Future<void>.delayed(latency);
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('simulated failure (debug button)');
    }
  }
}
