import 'package:backoffice/data/fake_review_queue.dart';
import 'package:backoffice/data/seed.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  final now = DateTime.utc(2026, 11, 4, 12);

  FakeReviewQueue queue() => FakeReviewQueue(seed: demoEntries(now), latency: Duration.zero);

  test('gives the proposals oldest first', () async {
    final items = await queue().pending();
    final times = items.map((item) => item.submittedAt).toList();

    expect(items.first.id, const EntryId('p-1'));
    expect(times, [...times]..sort());
  });

  test('finds the possible duplicates in the catalog (R5)', () async {
    final items = await queue().pending();

    expect(items.first.duplicates.single.id, const EntryId('c-1'));
  });

  test('a decided proposal leaves the queue', () async {
    final fake = queue();
    final entry = (await fake.find(const EntryId('p-1')))!;

    await fake.decide(publishEntry(entry, by: demoEditor, now: now, catalogId: entry.id).valueOrNull!);

    expect((await fake.pending()).map((item) => item.id), isNot(contains(const EntryId('p-1'))));
  });

  test('a restaurant published by the editor counts as a possible duplicate from then on', () async {
    final fake = queue();
    final dim = (await fake.find(const EntryId('p-11')))!;
    final copy = Entry(
      id: const EntryId('p-13'),
      owner: const UserId('marko'),
      source: const Manual(),
      status: PendingApproval(submittedAt: now),
      createdAt: now,
      content: dim.content,
    );
    final withCopy = FakeReviewQueue(seed: [...demoEntries(now), copy], latency: Duration.zero);

    await withCopy.decide(publishEntry(dim, by: demoEditor, now: now, catalogId: dim.id).valueOrNull!);

    final items = await withCopy.pending();
    expect(items.last.id, const EntryId('p-13'));
    expect(items.last.duplicates.single.id, const EntryId('p-11'));
  });

  test('the debug counters fail the next request and empty the next load', () async {
    final fake = queue()..failingRequests = 1;
    await expectLater(fake.pending(), throwsA(isA<RepositoryException>()));

    fake.emptyResponses = 1;
    expect(await fake.pending(), isEmpty);
    expect(await fake.pending(), isNotEmpty);
  });
}
