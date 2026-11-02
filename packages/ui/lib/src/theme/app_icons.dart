/// Icons from `packages/ui/assets/icons` (IK-… in `docs/dizajn/slike-i-ikonice.md`).
///
/// All are 24 × 24 line icons; `AppIcon` draws them in any color from `AppColors`.
enum AppIcons {
  library('ik-01-biblioteka'),
  map('ik-02-mapa'),
  add('ik-03-dodaj'),
  shoppingList('ik-04-lista'),
  profile('ik-05-profil'),
  search('ik-06-pretraga'),
  filter('ik-07-filter'),
  group('ik-08-grupa'),
  more('ik-09-jos'),
  recipe('ik-10-recept'),
  restaurant('ik-11-restoran'),
  time('ik-12-vreme'),
  calories('ik-14-kalorije'),
  cuisine('ik-15-kuhinja'),
  price('ik-16-cena'),
  link('ik-17-link'),
  original('ik-19-original'),
  location('ik-22-lokacija'),
  personal('ik-30-licno'),
  queued('ik-40-ceka'),
  analyzing('ik-41-analizira'),
  awaitingReview('ik-42-pregled'),
  saved('ik-43-sacuvano'),
  analysisFailed('ik-44-neuspeh'),
  pendingApproval('ik-45-urednik'),
  published('ik-46-katalog'),
  rejected('ik-47-odbijeno'),
  video('ik-51-video'),
  close('ik-91-zatvori'),
  edit('ik-92-uredi'),
  check('ik-94-kvacica'),
  notifications('ik-96-obavestenja'),
  next('ik-99-dalje');

  const AppIcons(this.file);

  final String file;

  String get path => 'assets/icons/$file.svg';
}

/// Illustrations from `packages/ui/assets/illustrations` (SL-… in `docs/dizajn/slike-i-ikonice.md`).
enum AppIllustrations {
  emptyLibrary('sl-10-prazna-biblioteka'),
  error('sl-12-greska'),
  breakfast('sl-20-dorucak'),
  mainCourse('sl-21-glavno-jelo'),
  pasta('sl-22-testenina'),
  restaurant('sl-26-restoran'),
  restaurantAsian('sl-26b-restoran-azijska'),
  video('sl-29-video');

  const AppIllustrations(this.file);

  final String file;

  String get path => 'assets/illustrations/$file.svg';
}
