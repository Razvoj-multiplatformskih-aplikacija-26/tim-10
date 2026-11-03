import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_entry_repository.dart';
import 'data/fake_video_analyzer.dart';
import 'data/seed.dart';

/// The one place that chooses the implementations of the ports.
///
/// Replacing the fake with the server in KT2 changes only this file; the screens stay the same.
final class AppDependencies {
  AppDependencies._({required this.entries, required this.clock, required this.user, this.fakeEntries});

  factory AppDependencies.fake({
    Clock clock = const SystemClock(),
    Duration latency = const Duration(milliseconds: 600),
    Duration analysisLatency = const Duration(milliseconds: 1200),
  }) {
    final entries = FakeEntryRepository(
      seed: demoEntries(clock.now()),
      clock: clock,
      analyzer: FakeVideoAnalyzer(demoVideos(), latency: analysisLatency),
      latency: latency,
    );
    return AppDependencies._(entries: entries, clock: clock, user: demoUser, fakeEntries: entries);
  }

  final EntryRepository entries;
  final Clock clock;
  final User user;

  /// The fake behind [entries], for the debug menu. `null` once the app talks to a real server.
  final FakeEntryRepository? fakeEntries;

  EntriesBloc entriesBloc() => EntriesBloc(
    loadMyEntries: LoadMyEntries(entries: entries),
    save: SaveEntry(entries: entries, clock: clock),
    propose: ProposeEntry(entries: entries, clock: clock),
    retry: RetryAnalysis(entries: entries, clock: clock),
    delete: DeleteEntry(entries: entries),
    user: user,
    clock: clock,
  );

  SubmitLinkBloc submitLinkBloc() => SubmitLinkBloc(
    loadMyEntries: LoadMyEntries(entries: entries),
    submitLink: SubmitLink(entries: entries, clock: clock),
    user: user,
    clock: clock,
  );
}
