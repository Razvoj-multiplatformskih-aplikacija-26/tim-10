import 'package:domain/domain.dart';

/// Demo data for KT1. Every time is counted back from `now`, so the demo looks the same on any day.
///
/// The backoffice has its own data; in KT1 the two apps are not connected, the server comes in KT2.

/// The signed-in editor in KT1 (login comes in KT2).
const demoEditor = User(id: UserId('urednik'), role: Role.editor);

/// Every proposal and the restaurants already in the catalog, for the fake repository.
List<Entry> demoEntries(DateTime now) {
  DateTime ago(Duration duration) => now.subtract(duration);
  Duration hours(int count) => Duration(hours: count);

  Entry proposal(
    String id,
    String owner,
    EntryContent content,
    Duration age, {
    PersonalLayer? personal,
    String? video,
  }) => Entry(
    id: EntryId(id),
    owner: UserId(owner),
    source: video == null
        ? const Manual()
        : FromVideo(link: VideoLink.parse(video).valueOrNull!, author: '@$owner.kuva'),
    status: PendingApproval(submittedAt: ago(age)),
    createdAt: ago(age + hours(30)),
    content: content,
    personal: personal ?? const PersonalLayer(),
  );

  Entry published(String id, RestaurantContent content, Duration age) => Entry(
    id: EntryId(id),
    owner: const UserId('jelena'),
    source: const Manual(),
    status: Published(by: demoEditor.id, at: ago(age), catalogId: EntryId(id)),
    createdAt: ago(age + hours(30)),
    content: content,
  );

  return [
    // The catalog: R5 compares proposals with these.
    published(
      'c-1',
      _restaurant('Bistro Paprika', 'Cara Dušana 12', 'domaća', ['gulaš', 'sarma'], 44.8205, 20.4600),
      hours(24 * 20),
    ),
    published(
      'c-2',
      _restaurant('Ramen bar Kinoko', 'Gospodar Jevremova 41', 'japanska', ['tonkotsu ramen'], 44.8215, 20.4610),
      hours(24 * 12),
    ),
    published(
      'c-3',
      _restaurant('Lipa', 'Kralja Petra 7', 'mediteranska', ['brancin'], 44.8180, 20.4550),
      hours(24 * 6),
    ),

    // The queue, oldest first. Two restaurants are possible duplicates of the catalog (R5).
    proposal(
      'p-1',
      'ana',
      _restaurant('Paprika', 'Cara Dušana 14', 'domaća', ['gulaš', 'pohovane paprike'], 44.8206, 20.4601),
      hours(53),
      video: 'https://www.instagram.com/reel/CPaprika01/',
      personal: const PersonalLayer(note: 'Bili smo za rođendan, skupo.', spent: 5400, wouldReturn: WouldReturn.maybe),
    ),
    proposal(
      'p-2',
      'marko',
      _recipe('Šakšuka', 20, 2, ['jaja', 'paradajz', 'paprika', 'kim'], ['Proprži papriku.', 'Dodaj paradajz i jaja.']),
      hours(50),
      video: 'https://www.tiktok.com/@marko/video/7300000000000000002',
    ),
    proposal(
      'p-3',
      'jovana',
      _recipe(
        'Pasta sa pestom',
        15,
        4,
        ['testenina', 'bosiljak', 'pinjoli', 'parmezan'],
        ['Skuvaj testeninu.', 'Izmiksaj pesto i pomešaj.'],
      ),
      hours(47),
    ),
    proposal(
      'p-4',
      'ana',
      _restaurant('Kinoko', 'Gospodar Jevremova 43', 'japanska', ['miso ramen', 'gjoza'], 44.8216, 20.4611),
      hours(31),
      video: 'https://www.instagram.com/reel/CKinoko002/',
    ),
    proposal(
      'p-5',
      'nikola',
      _restaurant('Pekara Zrno', 'Dobračina 4', 'pekara', ['kifla sa susamom', 'burek'], 44.8190, 20.4630),
      hours(29),
    ),
    proposal(
      'p-6',
      'milica',
      _recipe(
        'Palačinke sa bananom',
        10,
        2,
        ['banana', 'jaja', 'zobene pahuljice'],
        ['Izgnječi bananu.', 'Umuti sa jajima i ispeci.'],
      ),
      hours(26),
      video: 'https://www.instagram.com/reel/CPalacinke3/',
      personal: const PersonalLayer(note: 'Dodati malo cimeta.', modifications: 'Bez šećera.'),
    ),
    proposal(
      'p-7',
      'marko',
      _restaurant('Kafe Sunce', 'Strahinjića bana 7', 'doručak', ['jaja Benedikt'], 44.8240, 20.4590),
      hours(21),
    ),
    proposal(
      'p-8',
      'jovana',
      _recipe(
        'Ćevapi iz rerne',
        40,
        4,
        ['mleveno meso', 'beli luk', 'soda bikarbona'],
        ['Umesi meso i ostavi preko noći.', 'Oblikuj i peci 25 minuta.'],
      ),
      hours(16),
    ),
    proposal(
      'p-9',
      'stefan',
      _restaurant('Trattoria Nonna', 'Svetogorska 18', 'italijanska', ['lazanje', 'tiramisu'], 44.8120, 20.4700),
      hours(9),
      video: 'https://www.tiktok.com/@stefan/video/7300000000000000009',
    ),
    proposal(
      'p-10',
      'milica',
      _recipe(
        'Salata od leblebija',
        10,
        2,
        ['leblebije', 'krastavac', 'maslinovo ulje'],
        ['Iseci povrće.', 'Pomešaj sa leblebijama.'],
      ),
      hours(6),
    ),
    proposal(
      'p-11',
      'nikola',
      _restaurant('Dim', 'Vojvode Stepe 200', 'roštilj', ['rebarca', 'pljeskavica'], 44.7700, 20.4800),
      hours(3),
    ),
    proposal(
      'p-12',
      'ana',
      _recipe(
        'Kokos kari sa piletinom',
        35,
        3,
        ['piletina', 'kokosovo mleko', 'kari'],
        ['Proprži piletinu.', 'Dodaj začine i mleko, krčkaj 20 minuta.'],
      ),
      const Duration(minutes: 40),
    ),
  ];
}

RecipeContent _recipe(String title, int minutes, int servings, List<String> ingredients, List<String> steps) =>
    RecipeContent(
      title: title,
      ingredients: [for (final name in ingredients) Ingredient(name: name)],
      steps: steps,
      servings: servings,
      prepTime: Duration(minutes: minutes),
    );

RestaurantContent _restaurant(
  String name,
  String address,
  String cuisine,
  List<String> dishes,
  double latitude,
  double longitude,
) => RestaurantContent(
  name: name,
  location: Location(
    address: address,
    city: 'Beograd',
    coordinates: Coordinates(latitude: latitude, longitude: longitude),
  ),
  cuisine: cuisine,
  recommendedDishes: dishes,
  priceRange: PriceRange.moderate,
);
