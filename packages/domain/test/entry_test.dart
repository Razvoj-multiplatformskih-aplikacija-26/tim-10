import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 11, 3, 10);
  final link = VideoLink.parse('https://www.instagram.com/reel/C8xYz12AbC/').valueOrNull!;
  const recipe = RecipeContent(title: 'Palačinke', ingredients: [], steps: [], servings: 4);

  Entry awaitingReview() => Entry(
    id: const EntryId('e-1'),
    owner: const UserId('u-1'),
    source: FromVideo(link: link),
    status: AwaitingReview(analyzedAt: createdAt),
    createdAt: createdAt,
    content: recipe,
    personal: const PersonalLayer(note: 'Probati sa borovnicama.'),
  );

  group('Entry', () {
    test('copyWith(status:) changes only the status', () {
      final saved = awaitingReview().copyWith(status: Saved(at: createdAt));

      expect(saved.status, Saved(at: createdAt));
      expect(saved.content, recipe);
      expect(saved.personal, const PersonalLayer(note: 'Probati sa borovnicama.'));
      expect(saved.id, const EntryId('e-1'));
      expect(saved, isNot(awaitingReview()));
    });

    test('changing the personal layer leaves the content untouched', () {
      final edited = awaitingReview().copyWith(personal: const PersonalLayer(note: 'Bolje sa medom.'));

      expect(edited.content, awaitingReview().content);
    });

    test('entries with the same data are equal', () {
      expect(awaitingReview(), awaitingReview());
      expect(awaitingReview().hashCode, awaitingReview().hashCode);
    });

    test('a new entry has no content and an empty personal layer', () {
      final queued = Entry(
        id: const EntryId('e-2'),
        owner: const UserId('u-1'),
        source: FromVideo(link: link),
        status: Queued(at: createdAt),
        createdAt: createdAt,
      );

      expect(queued.content, isNull);
      expect(queued.personal, const PersonalLayer());
    });
  });

  group('EntrySource', () {
    test('three recipes from one video share the link and differ in the item index', () {
      final items = [for (var i = 0; i < 3; i++) FromVideo(link: link, itemIndex: i, itemCount: 3)];

      expect(items.map((item) => item.link).toSet(), {link});
      expect(items.map((item) => item.itemIndex), [0, 1, 2]);
      expect(items.toSet(), hasLength(3));
    });

    test('a manual entry has no link', () {
      const EntrySource source = Manual();

      expect(switch (source) {
        FromVideo(:final link) => link,
        Manual() => null,
      }, isNull);
    });
  });
}
