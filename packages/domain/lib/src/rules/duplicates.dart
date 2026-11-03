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

/// A name (or a city, or an address) in a form fit for comparing: lower case, plain Latin letters (Serbian Cyrillic
/// and accents turned into Latin, "Ћевабџиница" → "cevabdzinica", "Crème" → "creme"), no punctuation, and without the
/// words that only say what kind of place it is. "Bistro Paprika!" → "paprika".
String normalizeName(String name) {
  final plain = name.toLowerCase().split('').map((letter) => _plainLatin[letter] ?? letter).join();
  final words = plain.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').split(' ');
  return words.where((word) => word.isNotEmpty && !_ignoredWords.contains(word)).join(' ');
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

/// Each lower-case letter that is not plain a–z, with its plain Latin form. A letter missing here is dropped.
const _plainLatin = {
  // Serbian Latin
  'č': 'c', 'ć': 'c', 'š': 's', 'ž': 'z', 'đ': 'dj',
  // Serbian Cyrillic, written the same way as the Latin above
  'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd', 'ђ': 'dj', 'е': 'e', 'ж': 'z', 'з': 'z', 'и': 'i',
  'ј': 'j', 'к': 'k', 'л': 'l', 'љ': 'lj', 'м': 'm', 'н': 'n', 'њ': 'nj', 'о': 'o', 'п': 'p', 'р': 'r',
  'с': 's', 'т': 't', 'ћ': 'c', 'у': 'u', 'ф': 'f', 'х': 'h', 'ц': 'c', 'ч': 'c', 'џ': 'dz', 'ш': 's',
  // Accents common in restaurant names
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ñ': 'n', 'ç': 'c', 'ý': 'y', 'ÿ': 'y',
};

/// Words that say what kind of place it is, not which one.
const _ignoredWords = {'restoran', 'restaurant', 'bistro', 'kafana', 'picerija', 'pizzeria', 'cafe', 'kafe'};

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
