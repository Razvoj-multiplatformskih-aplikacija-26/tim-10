import 'dart:math';

import '../entry/entry.dart';
import '../entry/entry_content.dart';

/// R5: two places closer than this, with the same name, are the same restaurant.
const maxDuplicateDistanceMeters = 150;

/// R5 (README): the same restaurant exists only once in the catalog, across all users.
///
/// Returns the restaurants in [catalog] that may be the same as [candidate]: same city, same name (or one name
/// contains the other, "Kinoko" and "Ramen bar Kinoko"), and less than 150 m apart, or at the same address when
/// a place has no coordinates. The editor compares them side by side; the server joins exact duplicates (KT2).
List<Entry> possibleDuplicates(RestaurantContent candidate, List<Entry> catalog) => [
  for (final entry in catalog)
    if (entry.content case final RestaurantContent existing when _sameRestaurant(candidate, existing)) entry,
];

/// A name (or a city, or an address) in a form fit for comparing: lower case, Serbian letters without diacritics,
/// no punctuation, and without the words "restoran", "restaurant" and "bistro". "Bistro Paprika!" → "paprika".
String normalizeName(String name) {
  var text = name.toLowerCase();
  _withoutDiacritics.forEach((letter, plain) => text = text.replaceAll(letter, plain));
  text = text.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  return text.split(' ').where((word) => word.isNotEmpty && !_ignoredWords.contains(word)).join(' ');
}

/// The distance between two points on the Earth, in meters (the haversine formula).
double distanceMeters(Coordinates a, Coordinates b) {
  const earthRadiusMeters = 6371000.0;
  double radians(double degrees) => degrees * pi / 180;

  final dLat = radians(b.latitude - a.latitude);
  final dLng = radians(b.longitude - a.longitude);
  final h =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(radians(a.latitude)) * cos(radians(b.latitude)) * sin(dLng / 2) * sin(dLng / 2);
  return 2 * earthRadiusMeters * asin(sqrt(h));
}

const _withoutDiacritics = {'č': 'c', 'ć': 'c', 'š': 's', 'ž': 'z', 'đ': 'dj'};
const _ignoredWords = {'restoran', 'restaurant', 'bistro'};

bool _sameRestaurant(RestaurantContent a, RestaurantContent b) {
  if (normalizeName(a.location.city) != normalizeName(b.location.city)) return false;
  if (!_sameName(normalizeName(a.name), normalizeName(b.name))) return false;

  final here = a.location.coordinates;
  final there = b.location.coordinates;
  if (here != null && there != null) return distanceMeters(here, there) < maxDuplicateDistanceMeters;
  return normalizeName(a.location.address) == normalizeName(b.location.address);
}

/// Equal names, or every word of one name is in the other. Whole words only: "pap" is not "paprika".
bool _sameName(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  final wordsA = a.split(' ').toSet();
  final wordsB = b.split(' ').toSet();
  return wordsA.containsAll(wordsB) || wordsB.containsAll(wordsA);
}
