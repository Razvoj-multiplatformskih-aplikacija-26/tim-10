import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/fake_entry_repository.dart';
import 'package:mobile/data/fake_video_analyzer.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  const petar = UserId('u-petar');
  const ana = UserId('u-ana');
  final at = DateTime.utc(2026, 11, 4, 12);

  Entry entry(String id, UserId owner, {required Duration ago}) => Entry(
    id: EntryId(id),
    owner: owner,
    source: const Manual(),
    status: Saved(at: at),
    createdAt: at.subtract(ago),
  );

  final older = entry('petar-old', petar, ago: const Duration(days: 2));
  final newer = entry('petar-new', petar, ago: const Duration(hours: 1));
  final anas = entry('ana-1', ana, ago: const Duration(hours: 3));

  FakeEntryRepository repositoryWith({Duration latency = Duration.zero}) =>
      FakeEntryRepository(seed: [older, anas, newer], latency: latency);

  group('FakeEntryRepository', () {
    test('gives a user only their own entries, newest first', () async {
      final mine = await repositoryWith().entriesOf(petar);

      expect(mine.map((e) => e.id.value), ['petar-new', 'petar-old']);
    });

    test('waits like a network before answering', () async {
      final watch = Stopwatch()..start();

      await repositoryWith(latency: const Duration(milliseconds: 80)).entriesOf(petar);

      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(70));
    });

    test('"Simuliraj grešku" makes the next request fail, once', () async {
      final repository = repositoryWith()..failingRequests = 1;

      await expectLater(repository.entriesOf(petar), throwsA(isA<RepositoryException>()));
      expect(await repository.entriesOf(petar), hasLength(2));
    });

    test('"Prazan odgovor" makes the next load empty, once', () async {
      final repository = repositoryWith()..emptyResponses = 1;

      expect(await repository.entriesOf(petar), isEmpty);
      expect(await repository.entriesOf(petar), hasLength(2));
    });

    test('finds, saves and deletes an entry', () async {
      final repository = repositoryWith();
      final proposed = newer.copyWith(status: PendingApproval(submittedAt: at));

      await repository.save(proposed);
      expect(await repository.find(const EntryId('petar-new')), proposed);

      await repository.delete(const EntryId('petar-new'));
      expect(await repository.find(const EntryId('petar-new')), isNull);
      expect(await repository.entriesOf(petar), [older]);
    });
  });

  group('FakeVideoAnalyzer', () {
    final known = VideoLink.parse('https://www.instagram.com/reel/C8xYz12AbC/').valueOrNull!;
    final unknown = VideoLink.parse('https://www.tiktok.com/@neko/video/1234567890').valueOrNull!;
    const recipe = RecipeContent(title: 'Palačinke', ingredients: [], steps: [], servings: 4);
    final analyzer = FakeVideoAnalyzer({
      known: [recipe],
    }, latency: Duration.zero);

    test('a known video gives its prepared items', () async {
      expect(await analyzer.analyze(known), AnalysisSucceeded(AnalysisResult(link: known, items: const [recipe])));
    });

    test('any other video is not food, so the demo shows a failed analysis too', () async {
      expect(await analyzer.analyze(unknown), const AnalysisFailedWith(AnalysisFailure.notFood));
    });
  });
}
