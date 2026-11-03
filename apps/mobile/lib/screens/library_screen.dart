import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../router.dart';
import '../widgets/debug_menu.dart';
import '../widgets/entry_text.dart';
import '../widgets/entry_tile.dart';

/// M-03, the start screen. It only draws the state of the Bloc and sends events; the four states are a `switch`
/// without `default`, so a new state cannot be forgotten.
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<EntriesBloc, EntriesState>(
          builder: (context, state) => switch (state) {
            EntriesLoading() => const _Loading(),
            EntriesFailure() => _Message(
              child: ErrorState(
                title: 'Biblioteka se nije učitala',
                message: 'Server trenutno ne odgovara. Tvoji unosi nisu izgubljeni, samo ih sada ne možemo prikazati.',
                hint: 'Ako se ponavlja, proveri internet vezu.',
                onRetry: () => context.read<EntriesBloc>().add(const EntriesRequested()),
              ),
            ),
            EntriesEmpty() => _Message(
              child: EmptyState(
                title: 'Podeli prvi video sa hranom',
                message:
                    'Recept ili restoran iz Instagrama ili TikToka postaje unos koji možeš da pretražiš, skuvaš '
                    'ili posetiš.',
                actions: [
                  PrimaryButton(label: 'Dodaj link', icon: AppIcons.add, onPressed: () => context.push(addVideoPath)),
                ],
              ),
            ),
            EntriesLoaded() => _Loaded(state: state),
          },
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.screen, 10, 6, 10),
      child: Row(
        children: [
          Expanded(child: Text('Biblioteka', style: Theme.of(context).textTheme.headlineLarge)),
          const LibraryMenu(),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('library-loading'),
      children: [
        const _Title(),
        Expanded(
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpace.betweenCards),
            itemBuilder: (_, _) => const EntryCardSkeleton(),
          ),
        ),
      ],
    );
  }
}

/// The failure and the empty state: the title on top and one message in the middle of the screen.
class _Message extends StatelessWidget {
  const _Message({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Title(),
        Expanded(
          child: Center(
            child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpace.screen), child: child),
          ),
        ),
      ],
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.state});

  final EntriesLoaded state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<EntriesBloc>();
    final visible = state.visible;
    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(const EntriesRequested());
        await bloc.stream.firstWhere((state) => state is! EntriesLoading);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppSpace.betweenCards),
        children: [
          const _Title(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: SegmentedTabs(
              labels: const ['Sve', 'Recepti', 'Restorani'],
              selectedIndex: state.kind.index,
              onSelected: (index) => bloc.add(EntriesKindFilterChanged(KindFilter.values[index])),
            ),
          ),
          const SizedBox(height: 4),
          FilterChips(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            items: [
              FilterChipItem(label: 'Za pregled', count: _countOrNull(StatusFilter.forReview), highlighted: true),
              FilterChipItem(label: 'U obradi', count: _countOrNull(StatusFilter.processing)),
              const FilterChipItem(label: 'Sačuvano'),
              const FilterChipItem(label: 'U katalogu'),
              const FilterChipItem(label: 'Odbijeno'),
            ],
            selectedIndex: state.status?.index,
            onSelected: (index) => bloc.add(EntriesStatusFilterToggled(StatusFilter.values[index])),
          ),
          if (state.forReviewCount > 0 && state.status != StatusFilter.forReview)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, 6, AppSpace.screen, 0),
              child: ReviewBanner(
                title: _reviewTitle(state.forReviewCount),
                message: 'Proveri šta smo izdvojili i sačuvaj.',
                photos: [
                  for (final entry in state.entries)
                    if (entry.status is AwaitingReview) ?photoOf(entry),
                ].take(2).toList(),
                onPressed: () => bloc.add(const EntriesStatusFilterToggled(StatusFilter.forReview)),
              ),
            ),
          const SizedBox(height: AppSpace.betweenCards),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpace.screen),
              child: Text(
                'Nema unosa za ovaj izbor.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          for (final entry in visible)
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.betweenCards),
              child: EntryTile(key: ValueKey(entry.id.value), entry: entry),
            ),
        ],
      ),
    );
  }

  int? _countOrNull(StatusFilter chip) {
    final count = state.countFor(chip);
    return count == 0 ? null : count;
  }
}

/// "1 video čeka pregled", "2 videa čekaju pregled", "5 videa čeka pregled".
String _reviewTitle(int count) => switch (count) {
  1 => '1 video čeka pregled',
  2 || 3 || 4 => '$count videa čekaju pregled',
  _ => '$count videa čeka pregled',
};
