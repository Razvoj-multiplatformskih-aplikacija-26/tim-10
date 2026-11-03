import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026, 11, 4, 12);

  RestaurantContent restaurant(String name, {String address = 'Cara Dušana 12'}) => RestaurantContent(
    name: name,
    location: Location(address: address, city: 'Beograd'),
    cuisine: 'domaća',
    recommendedDishes: const ['gulaš'],
  );

  Entry entry(String id, EntryStatus status, {EntryContent? content}) => Entry(
    id: EntryId(id),
    owner: const UserId('ana'),
    source: const Manual(),
    status: status,
    createdAt: at,
    content: content,
    personal: const PersonalLayer(note: 'samo za Anu'),
  );

  final published = entry(
    'c-1',
    Published(by: const UserId('urednik'), at: at, catalogId: const EntryId('c-1')),
    content: restaurant('Bistro Paprika'),
  );

  group('ReviewItem.of', () {
    test('takes the row from a proposal waiting for an editor', () {
      final item = ReviewItem.of(
        entry('e-1', PendingApproval(submittedAt: at), content: restaurant('Lipa')),
        catalog: const [],
      );

      expect(item?.id, const EntryId('e-1'));
      expect(item?.proposedBy, const UserId('ana'));
      expect(item?.submittedAt, at);
    });

    test('gives no row for an entry in any other state', () {
      expect(
        ReviewItem.of(
          entry('e-1', Saved(at: at), content: restaurant('Lipa')),
          catalog: const [],
        ),
        isNull,
      );
      expect(ReviewItem.of(published, catalog: const []), isNull);
    });

    test('gives no row for a proposal without content', () {
      expect(ReviewItem.of(entry('e-1', PendingApproval(submittedAt: at)), catalog: const []), isNull);
    });
  });

  group('R5 · ReviewItem duplicates', () {
    test('lists the catalog restaurant with the same name and address', () {
      final item = ReviewItem.of(
        entry('e-1', PendingApproval(submittedAt: at), content: restaurant('Paprika')),
        catalog: [published],
      );

      expect(item?.duplicates, [CatalogMatch(id: const EntryId('c-1'), content: restaurant('Bistro Paprika'))]);
    });

    test('lists nothing for a restaurant at another address', () {
      final item = ReviewItem.of(
        entry(
          'e-1',
          PendingApproval(submittedAt: at),
          content: restaurant('Paprika', address: 'Dobračina 4'),
        ),
        catalog: [published],
      );

      expect(item?.duplicates, isEmpty);
    });

    test('lists nothing for a recipe', () {
      const recipe = RecipeContent(title: 'Paprika', ingredients: [], steps: [], servings: 2);
      final item = ReviewItem.of(
        entry('e-1', PendingApproval(submittedAt: at), content: recipe),
        catalog: [published],
      );

      expect(item?.duplicates, isEmpty);
    });
  });
}
