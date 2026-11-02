import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Every shared widget from `packages/ui` on one screen, to compare with `docs/dizajn/nacrti/m03-biblioteka.png`.
///
/// Only for checking the theme. It goes away once M-03 is built.
class UiShowcaseScreen extends StatefulWidget {
  const UiShowcaseScreen({super.key});

  @override
  State<UiShowcaseScreen> createState() => _UiShowcaseScreenState();
}

class _UiShowcaseScreenState extends State<UiShowcaseScreen> {
  static const _pancakes = AssetImage('assets/demo/palacinke.jpg');
  static const _ramen = AssetImage('assets/demo/ramen.jpg');
  static const _pasta = AssetImage('assets/demo/pasta.jpg');
  static const _bistro = AssetImage('assets/demo/bistro-paprike.jpg');
  static const _cevapi = AssetImage('assets/demo/cevapi.jpg');
  static const _shakshuka = AssetImage('assets/demo/saksuka.jpg');

  final _emptyLink = TextEditingController();
  final _validLink = TextEditingController(text: 'https://www.tiktok.com/@doruckuj.brzo/video/7301234567890');
  final _invalidLink = TextEditingController(text: 'palačinke sa bananom');

  var _segment = 0;
  int? _chip;
  var _tab = 0;

  @override
  void dispose() {
    _emptyLink.dispose();
    _validLink.dispose();
    _invalidLink.dispose();
    super.dispose();
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: SnackBarAction(label: 'Otvori', onPressed: () {}),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 10, AppSpace.screen, 32),
          children: [
            Text('Biblioteka', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 14),
            SegmentedTabs(
              labels: const ['Sve', 'Recepti', 'Restorani', 'Kolekcije'],
              selectedIndex: _segment,
              onSelected: (i) => setState(() => _segment = i),
            ),
            const SizedBox(height: 4),
            FilterChips(
              items: const [
                FilterChipItem(label: 'Za pregled', count: 2, highlighted: true),
                FilterChipItem(label: 'U obradi', count: 1),
                FilterChipItem(label: 'Sačuvano'),
                FilterChipItem(label: 'U katalogu'),
                FilterChipItem(label: 'Odbijeno'),
              ],
              selectedIndex: _chip,
              onSelected: (i) => setState(() => _chip = _chip == i ? null : i),
            ),
            const SizedBox(height: 6),
            ReviewBanner(
              title: '2 videa čekaju pregled',
              message: 'Proveri šta smo izdvojili i sačuvaj.',
              photos: const [_bistro, _pancakes],
              onPressed: () => _showSnackBar('Pregled dolazi uz M-07.'),
            ),
            const SizedBox(height: AppSpace.betweenCards),
            ..._cards(),
            const _Section('Bedževi stanja'),
            Wrap(spacing: 8, runSpacing: 8, children: [for (final status in BadgeStatus.values) StatusBadge(status)]),
            const _Section('Oznake tipa'),
            Wrap(spacing: 16, children: [for (final kind in EntryCardKind.values) TypeLabel(kind)]),
            const _Section('Učitavanje'),
            const EntryCardSkeleton(),
            const SizedBox(height: AppSpace.betweenCards),
            const EntryCardSkeleton(),
            const _Section('Prazno'),
            EmptyState(
              title: 'Podeli prvi video sa hranom',
              message:
                  'Recept ili restoran iz Instagrama ili TikToka postaje unos koji možeš da pretražiš, skuvaš '
                  'ili posetiš.',
              actions: [
                PrimaryButton(label: 'Dodaj link', icon: AppIcons.add, onPressed: () {}),
                GhostButton(label: 'Pogledaj primer', onPressed: () {}),
              ],
            ),
            const _Section('Greška'),
            ErrorState(
              title: 'Biblioteka se nije učitala',
              message: 'Server trenutno ne odgovara. Tvoji unosi nisu izgubljeni, samo ih sada ne možemo prikazati.',
              hint: 'Ako se ponavlja, proveri internet vezu.',
              onRetry: () => _showSnackBar('Pokušavamo ponovo.'),
            ),
            const _Section('Dugmad: 54, 50, 44, 36'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final size in ButtonSize.values) PrimaryButton(label: 'Sačuvaj', size: size, onPressed: () {}),
                for (final size in ButtonSize.values) GhostButton(label: 'Odustani', size: size, onPressed: () {}),
                const PrimaryButton(label: 'Isključeno', onPressed: null),
                const GhostButton(label: 'Isključeno', onPressed: null),
                GhostButton(label: 'Unesi ručno', icon: AppIcons.edit, size: ButtonSize.sm, onPressed: () {}),
              ],
            ),
            const SizedBox(height: 10),
            PrimaryButton(label: 'Analiziraj video', size: ButtonSize.xl, expanded: true, onPressed: () {}),
            const SizedBox(height: 10),
            const PrimaryButton(label: 'Šaljemo…', size: ButtonSize.xl, expanded: true, isBusy: true, onPressed: null),
            const _Section('Polje za link'),
            LinkField(controller: _emptyLink),
            const SizedBox(height: 16),
            LinkField(controller: _validLink, isValid: true),
            const SizedBox(height: 16),
            LinkField(
              controller: _invalidLink,
              errorText: 'Ovo ne liči na link do videa. Nalepi ceo link, na primer instagram.com/reel/…',
            ),
            const SizedBox(height: 16),
            LinkField(controller: _validLink, enabled: false),
            const _Section('SnackBar'),
            Align(
              alignment: Alignment.centerLeft,
              child: GhostButton(
                label: 'Prikaži SnackBar',
                size: ButtonSize.md,
                onPressed: () => _showSnackBar('Analiziramo video. Javićemo kad bude gotovo.'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppTabBar(
        currentIndex: _tab,
        onSelected: (i) => setState(() => _tab = i),
        onAdd: () => _showSnackBar('Dodaj video dolazi uz M-05.'),
      ),
    );
  }

  /// The seven cards from frames 1 and 1b of the M-03 draft, in the same order.
  List<Widget> _cards() {
    final theme = Theme.of(context);
    final cards = [
      const EntryCard(
        kind: EntryCardKind.recipe,
        status: BadgeStatus.awaitingReview,
        title: 'Proteinske palačinke sa bananom',
        thumb: ReelThumb(photo: _pancakes, sourceLabel: 'TikTok', stacked: true),
        facts: [
          EntryFact(icon: AppIcons.time, text: '15 min'),
          EntryFact(icon: AppIcons.calories, text: '310 kcal po porciji'),
        ],
        author: '@doruckuj.brzo',
        groupLabel: '1 od 3',
      ),
      const EntryCard(
        kind: EntryCardKind.restaurant,
        status: BadgeStatus.saved,
        title: 'Ramen bar Kinoko',
        thumb: ReelThumb(photo: _ramen, sourceLabel: 'Instagram'),
        facts: [
          EntryFact(icon: AppIcons.location, text: 'Dorćol'),
          EntryFact(icon: AppIcons.cuisine, text: 'Japanska'),
          EntryFact(icon: AppIcons.price, text: '€€'),
        ],
        personalNote: 'Vratio bih se',
        author: '@beograd.jede',
      ),
      const EntryCard(
        kind: EntryCardKind.unknown,
        status: BadgeStatus.analyzing,
        title: 'Izdvajamo recept iz videa',
        thumb: ReelThumb(photo: _shakshuka, sourceLabel: 'Instagram', dimmed: true),
        details: _AnalysisStep(step: 'Korak 2 od 4: slušamo govor', progress: 0.5),
        author: 'Javićemo ti kad završimo',
      ),
      const EntryCard(
        kind: EntryCardKind.recipe,
        status: BadgeStatus.published,
        title: 'Kremasta pasta sa pečurkama',
        thumb: ReelThumb(photo: _pasta, sourceLabel: 'TikTok'),
        facts: [
          EntryFact(icon: AppIcons.time, text: '25 min'),
          EntryFact(icon: AppIcons.calories, text: '540 kcal po porciji'),
        ],
        personalNote: 'Skuvano 2 puta, manje pavlake',
        author: '@vece.za.dvoje',
      ),
      const EntryCard(
        kind: EntryCardKind.restaurant,
        status: BadgeStatus.pendingApproval,
        title: 'Bistro Mala zemlja',
        thumb: ReelThumb(photo: _bistro, sourceLabel: 'TikTok', stacked: true),
        facts: [
          EntryFact(icon: AppIcons.location, text: 'Vračar'),
          EntryFact(icon: AppIcons.cuisine, text: 'Domaća'),
          EntryFact(icon: AppIcons.price, text: '€'),
        ],
        author: '@top10.bg',
        groupLabel: '4 od 10',
      ),
      EntryCard(
        kind: EntryCardKind.unknown,
        status: BadgeStatus.analysisFailed,
        title: 'Video nije dostupan',
        thumb: const ReelThumb(illustration: AppIllustrations.video, sourceLabel: 'Instagram'),
        details: Text(
          'Nalog je privatan ili je video obrisan, pa ga ne možemo otvoriti.',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.38,
            color: theme.colorScheme.onErrorContainer,
          ),
        ),
        actions: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GhostButton(label: 'Pokušaj ponovo', size: ButtonSize.sm, onPressed: () {}),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [AppIcon(AppIcons.edit, size: 15), SizedBox(width: 6), Text('Unesi ručno')],
              ),
            ),
          ],
        ),
      ),
      const EntryCard(
        kind: EntryCardKind.recipe,
        status: BadgeStatus.saved,
        title: 'Bakini ćevapi sa lukom',
        thumb: ReelThumb(photo: _cevapi, sourceLabel: 'Ručno'),
        facts: [
          EntryFact(icon: AppIcons.time, text: '40 min'),
          EntryFact(icon: AppIcons.calories, text: '620 kcal po porciji'),
        ],
        author: 'Tvoj recept',
      ),
    ];
    return [
      for (final card in cards) ...[card, const SizedBox(height: AppSpace.betweenCards)],
    ];
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Step text and progress bar of a card that is being analyzed.
class _AnalysisStep extends StatelessWidget {
  const _AnalysisStep({required this.step, required this.progress});

  final String step;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          step,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(value: progress, minHeight: 6),
        ),
      ],
    );
  }
}
