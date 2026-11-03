import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final yesterday = DateTime.utc(2026, 11, 2, 18);
  final now = DateTime.utc(2026, 11, 3, 18);
  VideoLink linkOf(String text) => VideoLink.parse(text).valueOrNull!;
  final video = linkOf('https://www.instagram.com/reel/C8xYz12AbC/');

  RecipeContent recipe(String title) =>
      RecipeContent(title: title, ingredients: const [], steps: const [], servings: 2);
  final items = [recipe('Palačinke'), recipe('Šakšuka'), recipe('Ovsena kaša')];

  /// Ana's entries for [link]: one per item, saved, with her private note.
  List<Entry> anasEntries(VideoLink link, {int? only}) => [
    for (var i = 0; i < items.length; i++)
      if (only == null || only == i)
        Entry(
          id: EntryId('ana-$i'),
          owner: const UserId('u-ana'),
          source: FromVideo(link: link, itemIndex: i, itemCount: items.length),
          status: Saved(at: yesterday),
          createdAt: yesterday,
          content: items[i],
          personal: const PersonalLayer(note: 'Anina privatna beleška'),
          analysisRequests: i == 0 ? [yesterday] : const [],
        ),
  ];

  group('R4 · existingAnalysisFor', () {
    test('finds another user\'s finished analysis with all its items, in order', () {
      expect(existingAnalysisFor(video, anasEntries(video)), AnalysisResult(link: video, items: items));
    });

    test('recognises the same video written differently', () {
      final sameVideo = linkOf('instagram.com/reel/C8xYz12AbC?igsh=abc');

      expect(existingAnalysisFor(sameVideo, anasEntries(video))?.items, items);
    });

    test('a different video has no existing analysis', () {
      expect(existingAnalysisFor(linkOf('instagram.com/reel/Drugi123'), anasEntries(video)), isNull);
    });

    test('an entry without content (queued, analysing or failed) is not an analysis', () {
      final failed = Entry(
        id: const EntryId('ana-x'),
        owner: const UserId('u-ana'),
        source: FromVideo(link: video),
        status: AnalysisFailed(reason: AnalysisFailure.timeout, at: yesterday),
        createdAt: yesterday,
      );

      expect(existingAnalysisFor(video, [failed]), isNull);
    });

    test('an incomplete set of items is not enough', () {
      expect(existingAnalysisFor(video, anasEntries(video, only: 1)), isNull);
    });

    test('items kept by different users still make the whole analysis', () {
      final mixed = [
        ...anasEntries(video, only: 0),
        ...anasEntries(video, only: 2),
        for (final e in anasEntries(video, only: 1))
          Entry(
            id: const EntryId('marko-1'),
            owner: const UserId('u-marko'),
            source: e.source,
            status: e.status,
            createdAt: e.createdAt,
            content: e.content,
          ),
      ];

      expect(existingAnalysisFor(video, mixed)?.items, items);
    });

    test('the whole flow: Petar gets a copy of all items, free of charge and without Ana\'s notes', () {
      final petarsLink = Entry(
        id: const EntryId('petar-1'),
        owner: const UserId('u-petar'),
        source: FromVideo(link: video),
        status: Queued(at: now),
        createdAt: now,
      );

      final existing = existingAnalysisFor(video, anasEntries(video))!;
      final petars = entriesFromAnalysis(
        petarsLink,
        existing,
        now: now,
        newId: (i) => EntryId('petar-1-$i'),
      ).valueOrNull!;

      expect(petars.map((e) => e.content), items);
      expect(petars.map((e) => e.owner).toSet(), {const UserId('u-petar')});
      expect(petars.map((e) => e.personal).toSet(), {const PersonalLayer()});
      expect(remainingAnalyses(petars, now: now), dailyAnalysisLimit);
    });
  });
}
