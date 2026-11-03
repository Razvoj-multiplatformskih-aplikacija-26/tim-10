import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_entry_repository.dart';
import 'package:mobile/data/fake_video_analyzer.dart';
import 'package:mobile/data/seed.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  final now = DateTime.utc(2026, 11, 5, 9);
  final all = demoEntries(now);
  final mine = [
    for (final entry in all)
      if (entry.owner == demoUser.id) entry,
  ];

  group('KT1 seed', () {
    test('the demo user has at least 10 entries', () {
      expect(mine.length, greaterThanOrEqualTo(10));
    });

    test('every one of the eight states is there', () {
      expect(mine.map((e) => e.status.runtimeType).toSet(), {
        Queued,
        Analyzing,
        AwaitingReview,
        Saved,
        AnalysisFailed,
        PendingApproval,
        Published,
        Rejected,
      });
    });

    test('there are recipes and restaurants', () {
      expect(mine.map((e) => e.content).whereType<RecipeContent>(), isNotEmpty);
      expect(mine.map((e) => e.content).whereType<RestaurantContent>(), isNotEmpty);
    });

    test('every entry is consistent with the domain: content exactly when the state has it', () {
      for (final entry in mine) {
        final hasContent = switch (entry.status) {
          Queued() || Analyzing() || AnalysisFailed() => false,
          AwaitingReview() || Saved() || PendingApproval() || Published() || Rejected() => true,
        };
        expect(entry.content != null, hasContent, reason: entry.id.value);
      }
    });

    test('nothing happens in the future', () {
      expect(all.where((e) => e.createdAt.isAfter(now)), isEmpty);
    });

    test('one analysis is about to leave the 24-hour window (R2)', () {
      final requests = [for (final e in mine) ...e.analysisRequests];
      final nearTheEdge = requests.where((at) {
        final age = now.difference(at);
        return age >= const Duration(hours: 23) && age < const Duration(hours: 24);
      });

      expect(nearTheEdge, isNotEmpty);
      expect(remainingAnalyses(mine, now: now), inInclusiveRange(1, dailyAnalysisLimit - 1));
    });

    test('a video with three recipes shows as three entries of one video', () {
      final grouped = [
        for (final entry in mine)
          if (entry.source case FromVideo(itemCount: 3)) entry,
      ];

      expect(grouped, hasLength(3));
    });

    test('R4 · the demo user gets Ana\'s video at once, without her notes', () async {
      final repository = FakeEntryRepository(
        seed: all,
        clock: FixedClock(now),
        analyzer: FakeVideoAnalyzer(demoVideos(), latency: Duration.zero),
        latency: Duration.zero,
      );

      final sent = await repository.submitLink(VideoLink.parse(anasVideoUrl).valueOrNull!, owner: demoUser.id);

      expect(sent.valueOrNull, hasLength(2));
      expect(sent.valueOrNull!.map((e) => e.status).toSet(), {AwaitingReview(analyzedAt: now)});
      expect(sent.valueOrNull!.map((e) => e.personal).toSet(), {const PersonalLayer()});
    });

    test('the known video is in the analyzer, with its author', () {
      final known = demoVideos()[VideoLink.parse(knownVideoUrl).valueOrNull!];

      expect(known?.items, hasLength(2));
      expect(known?.author, '@zdravo.brzo');
    });
  });
}
