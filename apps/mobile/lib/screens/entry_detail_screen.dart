import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../router.dart';
import '../widgets/confirm_dialogs.dart';
import '../widgets/entry_text.dart';

/// M-06, M-08 and M-10: one entry on its own screen. The id comes from the address, the entry from the same Bloc as the
/// library, so an action here is seen there at once.
class EntryDetailScreen extends StatelessWidget {
  const EntryDetailScreen({super.key, required this.id});

  final EntryId id;

  Entry? _entryIn(EntriesState state) =>
      state is EntriesLoaded ? state.entries.where((entry) => entry.id == id).firstOrNull : null;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EntriesBloc, EntriesState>(
      // The entry was here and is gone: it has just been deleted, so back to the library.
      listenWhen: (previous, current) =>
          _entryIn(previous) != null && current is EntriesLoaded && _entryIn(current) == null,
      listener: (context, state) => context.pop(),
      builder: (context, state) => switch (state) {
        EntriesLoading() => const _Frame(
          child: Padding(padding: EdgeInsets.all(AppSpace.screen), child: EntryCardSkeleton()),
        ),
        EntriesFailure() => _Frame(
          child: Center(
            child: ErrorState(
              title: 'Unos se nije učitao',
              message: 'Server trenutno ne odgovara. Tvoji unosi nisu izgubljeni.',
              onRetry: () => context.read<EntriesBloc>().add(const EntriesRequested()),
            ),
          ),
        ),
        EntriesEmpty() => const _NotFound(),
        EntriesLoaded() => switch (_entryIn(state)) {
          null => const _NotFound(),
          final entry => _EntryDetail(entry: entry, actions: state.actionsFor(id), isBusy: state.isBusy),
        },
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.actions = const [], this.bottom});

  final Widget child;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Nazad',
          icon: const AppIcon(AppIcons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go(libraryPath),
        ),
        actions: actions,
      ),
      body: child,
      bottomNavigationBar: bottom,
    );
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return _Frame(
      child: Center(
        child: EmptyState(
          title: 'Unos nije pronađen',
          message: 'Možda je obrisan.',
          actions: [GhostButton(label: 'Nazad u biblioteku', onPressed: () => context.go(libraryPath))],
        ),
      ),
    );
  }
}

class _EntryDetail extends StatefulWidget {
  const _EntryDetail({required this.entry, required this.actions, required this.isBusy});

  final Entry entry;

  /// What the domain allows now; the screen draws exactly these (Bloc's `actionsFor`).
  final Set<EntryAction> actions;
  final bool isBusy;

  @override
  State<_EntryDetail> createState() => _EntryDetailState();
}

class _EntryDetailState extends State<_EntryDetail> {
  var _tab = 0;

  void _run(EntryAction action) => context.read<EntriesBloc>().add(EntryActionRequested(action, widget.entry.id));

  Future<void> _delete() async {
    if (await confirmDelete(context, widget.entry)) _run(EntryAction.delete);
  }

  Future<void> _propose() async {
    if (await confirmPropose(context, widget.entry)) _run(EntryAction.propose);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final actions = widget.actions;
    final enabled = !widget.isBusy;
    final content = entry.content;
    return _Frame(
      actions: [
        if (actions.contains(EntryAction.delete))
          PopupMenuButton<EntryAction>(
            tooltip: 'Još',
            icon: const AppIcon(AppIcons.more),
            enabled: enabled,
            onSelected: (_) => _delete(),
            itemBuilder: (context) => const [PopupMenuItem(value: EntryAction.delete, child: Text('Obriši'))],
          ),
      ],
      bottom: _ActionBar(
        actions: actions,
        isBusy: widget.isBusy,
        isRejected: entry.status is Rejected,
        onSave: () => _run(EntryAction.save),
        onRetry: () => _run(EntryAction.retry),
        onPropose: _propose,
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.screen),
        children: [
          _Hero(entry: entry),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: StatusBadge(badgeStatusOf(entry.status))),
          const SizedBox(height: 10),
          Text(entryTitle(entry), style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          _Source(source: entry.source),
          const SizedBox(height: 10),
          Wrap(spacing: 14, runSpacing: 6, children: factsOf(content)),
          const SizedBox(height: 16),
          ...switch (content) {
            null => [_StatusExplanation(status: entry.status)],
            _ => [
              if (entry.status case Rejected(:final reason)) ...[
                _RejectionReason(reason: reason),
                const SizedBox(height: 16),
              ],
              SegmentedTabs(
                labels: [content is RecipeContent ? 'Recept' : 'Iz videa', 'Moje'],
                selectedIndex: _tab,
                onSelected: (index) => setState(() => _tab = index),
              ),
              const SizedBox(height: 16),
              if (_tab == 1)
                _PersonalTab(personal: entry.personal)
              else
                switch (content) {
                  final RecipeContent recipe => _RecipeTab(recipe: recipe),
                  final RestaurantContent restaurant => _RestaurantTab(restaurant: restaurant),
                },
            ],
          },
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final photo = photoOf(entry);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: photo == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Center(child: AppIllustration(illustrationOf(entry.content))),
              )
            : Image(image: photo, fit: BoxFit.cover),
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source({required this.source});

  final EntrySource source;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = switch (source) {
      FromVideo(:final link, :final author, :final itemIndex, :final itemCount) => [
        platformText(link.platform),
        ?author,
        if (itemCount > 1) '${itemIndex + 1} od $itemCount',
      ].join(' · '),
      Manual() => 'Tvoj unos',
    };
    return Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant));
  }
}

/// M-06: while there is no content, the screen says what is going on, in words.
class _StatusExplanation extends StatelessWidget {
  const _StatusExplanation({required this.status});

  final EntryStatus status;

  @override
  Widget build(BuildContext context) {
    final text = switch (status) {
      Queued() => 'Video je na redu za analizu. Možeš da zatvoriš aplikaciju; javićemo kad bude gotovo.',
      Analyzing() =>
        'Slušamo govor i tražimo recept ili restoran. Možeš da zatvoriš aplikaciju; javićemo kad bude gotovo.',
      AnalysisFailed(:final reason) => analysisFailureText(reason),
      AwaitingReview() || Saved() || PendingApproval() || Published() || Rejected() => '',
    };
    return Text(text, style: Theme.of(context).textTheme.bodyLarge);
  }
}

class _RejectionReason extends StatelessWidget {
  const _RejectionReason({required this.reason});

  final RejectionReason reason;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpace.insideCard),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Text(
        'Urednik je odbio predlog: ${reason.text}',
        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class _RecipeTab extends StatelessWidget {
  const _RecipeTab({required this.recipe});

  final RecipeContent recipe;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Heading('Sastojci'),
        for (final ingredient in recipe.ingredients) Text('• ${ingredientText(ingredient)}', style: body),
        const SizedBox(height: 16),
        const _Heading('Koraci'),
        if (recipe.steps.isEmpty) Text('U videu nisu navedeni koraci.', style: body),
        for (final (index, step) in recipe.steps.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('${index + 1}. $step', style: body),
          ),
      ],
    );
  }
}

class _RestaurantTab extends StatelessWidget {
  const _RestaurantTab({required this.restaurant});

  final RestaurantContent restaurant;

  @override
  Widget build(BuildContext context) {
    final body = Theme.of(context).textTheme.bodyLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Heading('Adresa'),
        Text('${restaurant.location.address}, ${restaurant.location.city}', style: body),
        const SizedBox(height: 16),
        const _Heading('Preporučena jela'),
        for (final dish in restaurant.recommendedDishes) Text('• $dish', style: body),
        if (restaurant.notes case final notes?) ...[
          const SizedBox(height: 16),
          const _Heading('Napomena iz videa'),
          Text(notes, style: body),
        ],
      ],
    );
  }
}

/// The personal layer: only the owner reaches this screen, and it is kept apart from what the AI extracted (R7).
class _PersonalTab extends StatelessWidget {
  const _PersonalTab({required this.personal});

  final PersonalLayer personal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = personalSummary(personal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privatno: vidiš samo ti, nikad urednik.',
          style: AppText.label.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        if (summary == null) Text('Još nemaš beleški za ovaj unos.', style: theme.textTheme.bodyLarge),
        if (summary != null) PersonalNote(summary),
        if (personal.spent case final spent?) ...[
          const SizedBox(height: 10),
          Text('Potrošio sam: $spent din', style: theme.textTheme.bodyLarge),
        ],
        if (personal.modifications case final modifications?) ...[
          const SizedBox(height: 10),
          Text('Moje izmene: $modifications', style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }
}

/// The main action of the entry's state, at the bottom of the screen. Empty when the domain allows none (R3).
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.actions,
    required this.isBusy,
    required this.isRejected,
    required this.onSave,
    required this.onRetry,
    required this.onPropose,
  });

  final Set<EntryAction> actions;
  final bool isBusy;
  final bool isRejected;
  final VoidCallback onSave;
  final VoidCallback onRetry;
  final VoidCallback onPropose;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[
      if (actions.contains(EntryAction.save))
        PrimaryButton(label: 'Sačuvaj', expanded: true, isBusy: isBusy, onPressed: isBusy ? null : onSave),
      if (actions.contains(EntryAction.retry))
        PrimaryButton(label: 'Pokušaj ponovo', expanded: true, isBusy: isBusy, onPressed: isBusy ? null : onRetry),
      if (actions.contains(EntryAction.propose))
        PrimaryButton(
          label: isRejected ? 'Predloži ponovo' : 'Predloži za katalog',
          expanded: true,
          isBusy: isBusy,
          onPressed: isBusy ? null : onPropose,
        ),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, 8, AppSpace.screen, 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: buttons),
      ),
    );
  }
}
