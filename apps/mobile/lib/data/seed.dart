import 'package:domain/domain.dart';

/// Demo data for KT1. Every time is counted back from `now`, so the demo looks the same on any day.
///
/// Links for the defense (also in `docs/kt1-plan.md`):
/// - [knownVideoUrl] is analysed successfully (two salads);
/// - [anasVideoUrl] was already analysed by Ana, so the result comes at once (R4);
/// - any other Instagram or TikTok video link ends as "U videu nismo prepoznali recept ni restoran".

/// The signed-in user in KT1 (login comes in KT2).
const demoUser = User(id: UserId('u-demo'), role: Role.user);

/// Another user, whose entries the demo user never sees; they are here for R4.
const ana = UserId('u-ana');

const _editor = UserId('u-editor');

const knownVideoUrl = 'https://www.instagram.com/reel/CSalate2026/';
const anasVideoUrl = 'https://www.instagram.com/reel/CDorcolTop2/';

/// The videos the fake analyzer knows.
Map<VideoLink, AnalysisResult> demoVideos() {
  final salads = _link(knownVideoUrl);
  return {
    salads: AnalysisResult(
      link: salads,
      author: '@zdravo.brzo',
      items: [
        _recipe(
          'Salata od leblebija',
          minutes: 10,
          servings: 2,
          ingredients: [
            _ingredient('leblebije, kuvane', 400, Unit.g),
            _ingredient('krastavac', 1, Unit.piece),
            _ingredient('maslinovo ulje', 2, Unit.tbsp),
            const Ingredient(name: 'so'),
          ],
        ),
        _recipe(
          'Grčka salata',
          minutes: 10,
          servings: 2,
          ingredients: [
            _ingredient('paradajz', 3, Unit.piece),
            _ingredient('feta sir', 150, Unit.g),
            _ingredient('masline', 50, Unit.g),
          ],
        ),
      ],
    ),
  };
}

/// Everyone's entries: the demo user's library (about 14 entries in all eight states) and Ana's.
List<Entry> demoEntries(DateTime now) {
  Duration minutes(int m) => Duration(minutes: m);
  Duration hours(int h) => Duration(hours: h);
  Duration days(int d) => Duration(days: d);
  DateTime ago(Duration d) => now.subtract(d);

  final breakfast = _link('https://www.tiktok.com/@doruckuj.brzo/video/7301234567890123456');
  final breakfastAt = ago(hours(3));
  final rejectionReason = RejectionReason.parse('Video prikazuje samo gotovo jelo, bez pripreme.').valueOrNull!;

  Entry demo(
    String id, {
    required String url,
    required EntryStatus status,
    required DateTime createdAt,
    EntryContent? content,
    String? author,
    String? thumbnail,
    PersonalLayer personal = const PersonalLayer(),
  }) => Entry(
    id: EntryId(id),
    owner: demoUser.id,
    source: FromVideo(link: _link(url), author: author, thumbnail: thumbnail),
    status: status,
    createdAt: createdAt,
    content: content,
    personal: personal,
    analysisRequests: [createdAt],
  );

  return [
    // Čeka analizu, Analizira se: no content yet.
    demo(
      'd-queued',
      url: 'https://www.tiktok.com/@kuhinja.za.dvoje/video/7311111111111111111',
      status: Queued(at: ago(minutes(2))),
      createdAt: ago(minutes(2)),
      author: '@kuhinja.za.dvoje',
    ),
    demo(
      'd-analyzing',
      url: 'https://www.instagram.com/reel/CAnalizaTraje/',
      status: Analyzing(startedAt: ago(minutes(1))),
      createdAt: ago(minutes(6)),
      author: '@beograd.jede',
    ),

    // Za pregled: one video with three recipes, "1 od 3", "2 od 3", "3 od 3"; the third has no photo.
    for (final (i, (title, photo, minutes)) in [
      ('Proteinske palačinke sa bananom', 'palacinke', 15),
      ('Šakšuka za dvoje', 'saksuka', 25),
      ('Ovsena kaša sa jabukom', null, 10),
    ].indexed)
      Entry(
        id: EntryId('d-breakfast-$i'),
        owner: demoUser.id,
        source: FromVideo(link: breakfast, itemIndex: i, itemCount: 3, author: '@doruckuj.brzo', thumbnail: photo),
        status: AwaitingReview(analyzedAt: breakfastAt.add(const Duration(minutes: 1))),
        createdAt: breakfastAt,
        content: _recipe(title, minutes: minutes, servings: 2),
        analysisRequests: i == 0 ? [breakfastAt] : const [],
      ),

    // Nije uspelo, 23 hours ago: still inside the 24-hour window of R2, and it leaves it in an hour.
    demo(
      'd-failed',
      url: 'https://www.instagram.com/reel/CPrivatanNalog/',
      status: AnalysisFailed(reason: AnalysisFailure.unavailable, at: ago(hours(23)).add(minutes(1))),
      createdAt: ago(hours(23)),
      author: '@zatvoren.profil',
    ),

    // Sačuvano.
    demo(
      'd-pasta',
      url: 'https://www.instagram.com/reel/CPastaLimun1/',
      status: Saved(at: ago(days(2))),
      createdAt: ago(days(2)),
      author: '@testenina.svaki.dan',
      thumbnail: 'pasta',
      content: _recipe(
        'Pasta sa limunom i parmezanom',
        minutes: 20,
        servings: 2,
        ingredients: [
          _ingredient('špagete', 200, Unit.g),
          _ingredient('limun', 1, Unit.piece),
          _ingredient('parmezan', 50, Unit.g),
        ],
      ),
      personal: const PersonalLayer(note: 'Duplo više limuna.', modifications: 'Dodala sam bosiljak.'),
    ),
    demo(
      'd-ramen',
      url: 'https://www.instagram.com/reel/C9xKq2LtR4a/',
      status: Saved(at: ago(days(4))),
      createdAt: ago(days(4)),
      author: '@beograd.jede',
      thumbnail: 'ramen',
      content: _restaurant(
        'Ramen bar Kinoko',
        address: 'Cara Dušana 10',
        cuisine: 'japanska',
        dishes: ['tonkotsu ramen', 'gyoza'],
        price: PriceRange.moderate,
        latitude: 44.8226,
        longitude: 20.4627,
      ),
      personal: const PersonalLayer(note: 'Probati i ljuti ramen.', spent: 2400, wouldReturn: WouldReturn.yes),
    ),
    demo(
      'd-pizza',
      url: 'https://www.tiktok.com/@picerije.bg/video/7333333333333333333',
      status: Saved(at: ago(days(6))),
      createdAt: ago(days(6)),
      author: '@picerije.bg',
      content: _restaurant(
        'Pica Mare',
        address: 'Gospodar Jevremova 20',
        cuisine: 'italijanska',
        dishes: ['margarita', 'pica sa tartufima'],
        price: PriceRange.budget,
      ),
    ),

    // Čeka urednika.
    demo(
      'd-paprika',
      url: 'https://www.instagram.com/reel/CBistroPaprik/',
      status: PendingApproval(submittedAt: ago(days(1))),
      createdAt: ago(days(3)),
      author: '@beograd.jede',
      thumbnail: 'bistro-paprike',
      content: _restaurant(
        'Bistro Paprika',
        address: 'Cetinjska 15',
        cuisine: 'srpska',
        dishes: ['punjene paprike', 'ajvar'],
        price: PriceRange.moderate,
        latitude: 44.8176,
        longitude: 20.4633,
      ),
    ),

    // U katalogu.
    demo(
      'd-cevapi',
      url: 'https://www.tiktok.com/@rostilj.kod.kuce/video/7322222222222222222',
      status: Published(by: _editor, at: ago(days(5)), catalogId: const EntryId('c-cevapi')),
      createdAt: ago(days(9)),
      author: '@rostilj.kod.kuce',
      thumbnail: 'cevapi',
      content: _recipe(
        'Ćevapi na tavi',
        minutes: 30,
        servings: 4,
        ingredients: [
          _ingredient('mleveno meso', 600, Unit.g),
          _ingredient('crni luk', 1, Unit.piece),
          _ingredient('soda bikarbona', 1, Unit.tsp),
        ],
      ),
    ),
    demo(
      'd-lipa',
      url: 'https://www.instagram.com/reel/CKafanaLipa1/',
      status: Published(by: _editor, at: ago(days(8)), catalogId: const EntryId('c-lipa')),
      createdAt: ago(days(12)),
      author: '@kafane.srbije',
      content: _restaurant(
        'Kafana Lipa',
        address: 'Skadarska 31',
        cuisine: 'srpska',
        dishes: ['teleća čorba', 'karađorđeva'],
        price: PriceRange.moderate,
        latitude: 44.8183,
        longitude: 20.4669,
      ),
    ),

    // Odbijeno.
    demo(
      'd-smoothie',
      url: 'https://www.tiktok.com/@smoothie.svet/video/7344444444444444444',
      status: Rejected(by: _editor, reason: rejectionReason, at: ago(days(2))),
      createdAt: ago(days(7)),
      author: '@smoothie.svet',
      content: _recipe(
        'Zeleni smoothie',
        minutes: 5,
        servings: 1,
        ingredients: [_ingredient('spanać', 50, Unit.g), _ingredient('kivi', 2, Unit.piece)],
      ),
    ),

    // Ana's video with two restaurants: complete, so the demo user gets it at once (R4).
    for (final (i, place) in [
      _restaurant('Pekara Zrno', address: 'Dobračina 4', cuisine: 'pekara', dishes: ['kifla sa susamom']),
      _restaurant('Kafe Sunce', address: 'Strahinjića bana 7', cuisine: 'doručak', dishes: ['jaja Benedikt']),
    ].indexed)
      Entry(
        id: EntryId('ana-dorcol-$i'),
        owner: ana,
        source: FromVideo(link: _link(anasVideoUrl), itemIndex: i, itemCount: 2, author: '@ana.jede'),
        status: Saved(at: ago(days(1))),
        createdAt: ago(days(1)),
        content: place,
        personal: const PersonalLayer(note: 'Anina beleška, nikad je ne vidi drugi korisnik.'),
        analysisRequests: i == 0 ? [ago(days(1))] : const [],
      ),
  ];
}

VideoLink _link(String url) => VideoLink.parse(url).valueOrNull!;

Ingredient _ingredient(String name, double amount, Unit unit) =>
    Ingredient(name: name, quantity: Quantity(amount, unit));

RecipeContent _recipe(
  String title, {
  required int minutes,
  required int servings,
  List<Ingredient> ingredients = const [],
}) => RecipeContent(
  title: title,
  ingredients: ingredients,
  steps: const ['Pripremiti sastojke.', 'Skuvati ili ispeći po uputstvu iz videa.', 'Poslužiti.'],
  servings: servings,
  prepTime: Duration(minutes: minutes),
);

RestaurantContent _restaurant(
  String name, {
  required String address,
  required String cuisine,
  required List<String> dishes,
  PriceRange? price,
  double? latitude,
  double? longitude,
}) => RestaurantContent(
  name: name,
  location: Location(
    address: address,
    city: 'Beograd',
    coordinates: latitude == null || longitude == null ? null : Coordinates(latitude: latitude, longitude: longitude),
  ),
  cuisine: cuisine,
  recommendedDishes: dishes,
  priceRange: price,
);
