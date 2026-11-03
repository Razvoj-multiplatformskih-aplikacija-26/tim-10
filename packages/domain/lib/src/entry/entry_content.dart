import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../identifiers.dart';

/// What the AI extracted from a video (or the user typed in): a recipe or a restaurant.
///
/// Plain data in KT1. Limits such as "amount > 0" or "1–24 servings" (R8) come with the forms that need them.
sealed class EntryContent {
  const EntryContent();
}

// Recipe

enum Unit { g, kg, ml, l, piece, tbsp, tsp, cup }

@immutable
final class Quantity {
  const Quantity(this.amount, this.unit);

  /// A `double`, because on the web `int` and `double` are the same number anyway.
  final double amount;
  final Unit unit;

  @override
  bool operator ==(Object other) => other is Quantity && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);

  @override
  String toString() => 'Quantity($amount ${unit.name})';
}

@immutable
final class Ingredient {
  const Ingredient({required this.name, this.quantity, this.foodId});

  final String name;

  /// `null` for "to taste" (salt, pepper).
  final Quantity? quantity;

  /// The matching food in the curated database, when there is one (for nutrition, after KT1).
  final FoodId? foodId;

  @override
  bool operator ==(Object other) =>
      other is Ingredient && other.name == name && other.quantity == quantity && other.foodId == foodId;

  @override
  int get hashCode => Object.hash(name, quantity, foodId);
}

@immutable
final class RecipeContent extends EntryContent {
  const RecipeContent({
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.servings,
    this.prepTime,
  });

  final String title;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final int servings;
  final Duration? prepTime;

  @override
  bool operator ==(Object other) =>
      other is RecipeContent &&
      other.title == title &&
      const ListEquality<Ingredient>().equals(other.ingredients, ingredients) &&
      const ListEquality<String>().equals(other.steps, steps) &&
      other.servings == servings &&
      other.prepTime == prepTime;

  @override
  int get hashCode => Object.hash(title, Object.hashAll(ingredients), Object.hashAll(steps), servings, prepTime);
}

// Restaurant

enum PriceRange { budget, moderate, expensive, luxury }

@immutable
final class Coordinates {
  const Coordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) => other is Coordinates && other.latitude == latitude && other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

@immutable
final class Location {
  const Location({required this.address, required this.city, this.coordinates});

  final String address;
  final String city;

  /// `null` when the video does not say where exactly; R5 then compares the address.
  final Coordinates? coordinates;

  @override
  bool operator ==(Object other) =>
      other is Location && other.address == address && other.city == city && other.coordinates == coordinates;

  @override
  int get hashCode => Object.hash(address, city, coordinates);
}

@immutable
final class RestaurantContent extends EntryContent {
  const RestaurantContent({
    required this.name,
    required this.location,
    required this.cuisine,
    required this.recommendedDishes,
    this.priceRange,
    this.notes,
  });

  final String name;
  final Location location;
  final String cuisine;
  final List<String> recommendedDishes;
  final PriceRange? priceRange;
  final String? notes;

  @override
  bool operator ==(Object other) =>
      other is RestaurantContent &&
      other.name == name &&
      other.location == location &&
      other.cuisine == cuisine &&
      const ListEquality<String>().equals(other.recommendedDishes, recommendedDishes) &&
      other.priceRange == priceRange &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(name, location, cuisine, Object.hashAll(recommendedDishes), priceRange, notes);
}
