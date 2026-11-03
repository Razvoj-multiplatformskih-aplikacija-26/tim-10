import 'dart:math';

import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final at = DateTime.utc(2026, 11, 3, 12);
  const paprikaPlace = Coordinates(latitude: 44.8176, longitude: 20.4633);

  /// A point [meters] north of [from]: along a meridian the haversine distance is exactly radius × angle.
  Coordinates north(Coordinates from, double meters) =>
      Coordinates(latitude: from.latitude + meters / (6371000.0 * pi / 180), longitude: from.longitude);

  RestaurantContent restaurant(
    String name, {
    String city = 'Beograd',
    String address = 'Cetinjska 15',
    Coordinates? coordinates = paprikaPlace,
  }) => RestaurantContent(
    name: name,
    location: Location(address: address, city: city, coordinates: coordinates),
    cuisine: 'srpska',
    recommendedDishes: const [],
  );

  var nextId = 0;
  Entry published(EntryContent content) => Entry(
    id: EntryId('c-${nextId++}'),
    owner: const UserId('u-ana'),
    source: const Manual(),
    status: Published(by: const UserId('u-editor'), at: at, catalogId: const EntryId('c')),
    createdAt: at,
    content: content,
  );

  group('R5 · normalizeName', () {
    test('drops case, diacritics, punctuation and the word "bistro"', () {
      expect(normalizeName('Bistro Paprika!'), 'paprika');
      expect(normalizeName('Čevabdžinica Željo'), 'cevabdzinica zeljo');
      expect(normalizeName('Đurđevak, restoran'), 'djurdjevak');
    });
  });

  group('R5 · distanceMeters', () {
    test('is zero for the same point and about 1 km for 1 km north', () {
      expect(distanceMeters(paprikaPlace, paprikaPlace), 0);
      expect(distanceMeters(paprikaPlace, north(paprikaPlace, 1000)), closeTo(1000, 0.001));
    });
  });

  group('R5 · possibleDuplicates', () {
    test('finds the same restaurant under a slightly different name', () {
      final catalog = [published(restaurant('Paprika'))];

      expect(possibleDuplicates(restaurant('Bistro Paprika'), catalog), catalog);
    });

    test('one name may contain the other, as whole words', () {
      final catalog = [published(restaurant('Ramen bar Kinoko'))];

      expect(possibleDuplicates(restaurant('Kinoko'), catalog), catalog);
      expect(possibleDuplicates(restaurant('Kino'), catalog), isEmpty);
    });

    test('149 m apart is a duplicate', () {
      final catalog = [published(restaurant('Paprika', coordinates: north(paprikaPlace, 149)))];

      expect(possibleDuplicates(restaurant('Paprika'), catalog), hasLength(1));
    });

    test('151 m apart is not (two places of a chain)', () {
      final catalog = [published(restaurant('Paprika', coordinates: north(paprikaPlace, 151)))];

      expect(possibleDuplicates(restaurant('Paprika'), catalog), isEmpty);
    });

    test('the same name in another city is not a duplicate', () {
      final catalog = [published(restaurant('Paprika', city: 'Novi Sad'))];

      expect(possibleDuplicates(restaurant('Paprika'), catalog), isEmpty);
    });

    test('without coordinates the address decides', () {
      final catalog = [
        published(restaurant('Paprika', address: 'Cetinjska 15.', coordinates: null)),
        published(restaurant('Paprika', address: 'Knez Mihailova 1', coordinates: null)),
      ];

      expect(possibleDuplicates(restaurant('Paprika', address: 'cetinjska 15', coordinates: null), catalog), [
        catalog.first,
      ]);
    });

    test('a recipe is never a duplicate of a restaurant', () {
      final catalog = [published(const RecipeContent(title: 'Paprika', ingredients: [], steps: [], servings: 2))];

      expect(possibleDuplicates(restaurant('Paprika'), catalog), isEmpty);
    });
  });
}
