import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  RecipeContent shakshuka({String salt = 'so'}) => RecipeContent(
    title: 'Šakšuka',
    ingredients: [
      const Ingredient(name: 'jaja', quantity: Quantity(4, Unit.piece)),
      const Ingredient(name: 'paradajz', quantity: Quantity(400, Unit.g), foodId: FoodId('f-paradajz')),
      Ingredient(name: salt),
    ],
    steps: ['Ispržiti luk i papriku.', 'Dodati paradajz.', 'Ubaciti jaja i poklopiti.'],
    servings: 2,
    prepTime: const Duration(minutes: 25),
  );

  RestaurantContent bistro({List<String> dishes = const ['pljeskavica', 'ajvar']}) => RestaurantContent(
    name: 'Bistro Paprika',
    location: const Location(
      address: 'Cetinjska 15',
      city: 'Beograd',
      coordinates: Coordinates(latitude: 44.8176, longitude: 20.4633),
    ),
    cuisine: 'srpska',
    recommendedDishes: dishes,
    priceRange: PriceRange.moderate,
  );

  /// What an app does with content: one branch per kind, no `default`.
  String kindOf(EntryContent content) => switch (content) {
    RecipeContent() => 'recipe',
    RestaurantContent() => 'restaurant',
  };

  group('EntryContent', () {
    test('two recipes with the same data are equal, list by list', () {
      expect(shakshuka(), shakshuka());
      expect(shakshuka().hashCode, shakshuka().hashCode);
      expect(shakshuka(), isNot(shakshuka(salt: 'morska so')));
    });

    test('two restaurants with the same data are equal, list by list', () {
      expect(bistro(), bistro());
      expect(bistro(), isNot(bistro(dishes: ['pljeskavica'])));
    });

    test('an ingredient may have no quantity ("to taste")', () {
      expect(const Ingredient(name: 'so').quantity, isNull);
    });

    test('content is either a recipe or a restaurant', () {
      expect(kindOf(shakshuka()), 'recipe');
      expect(kindOf(bistro()), 'restaurant');
    });
  });
}
