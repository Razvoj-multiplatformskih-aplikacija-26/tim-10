import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
import '../widgets/entry_text.dart';

/// M-05, the form "Dodaj video": R1 is checked while typing, R2 is visible before sending.
///
/// The rules are in the domain and the Bloc calls them; the screen only chooses the words for what they answered.
class AddVideoScreen extends StatefulWidget {
  const AddVideoScreen({super.key});

  @override
  State<AddVideoScreen> createState() => _AddVideoScreenState();
}

class _AddVideoScreenState extends State<AddVideoScreen> {
  final _link = TextEditingController();

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _showOutcome(BuildContext context, SubmitLinkState state) {
    final notice = state.notice;
    if (notice == null) return;

    final bloc = context.read<SubmitLinkBloc>();
    final messenger = ScaffoldMessenger.of(context);
    void show(String text, {SnackBarAction? action}) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), action: action));

    switch (notice) {
      case SubmitSucceeded(:final alreadyAnalyzed):
        show(
          alreadyAnalyzed
              ? 'Ovaj video je već analiziran. Rezultat je odmah tu.'
              : 'Analiziramo video. Javićemo kad bude gotovo.',
        );
        context.read<EntriesBloc>().add(const EntriesRequested(showAll: true));
        context.pop();
      case SubmitRejected(:final error):
        show(domainErrorText(error, now: context.read<AppDependencies>().clock.now()));
      case SubmitFailed():
        show(
          'Slanje nije uspelo. Proveri internet vezu.',
          action: SnackBarAction(label: 'Pokušaj ponovo', onPressed: () => bloc.add(const LinkSubmitted())),
        );
    }
    bloc.add(const SubmitLinkNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<SubmitLinkBloc, SubmitLinkState>(
      listenWhen: (previous, current) => current.notice != null && previous.notice != current.notice,
      listener: _showOutcome,
      builder: (context, state) {
        final bloc = context.read<SubmitLinkBloc>();
        final now = context.read<AppDependencies>().clock.now();
        final linkError = state.linkError;
        final limitError = state.limitError;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              tooltip: 'Zatvori',
              icon: const AppIcon(AppIcons.close),
              onPressed: state.isSending ? null : () => context.pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.screen),
            children: [
              Text('Dodaj video', style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Nalepi link sa Instagrama ili TikToka. Mi izdvojimo recept ili restoran, a ti potvrdiš.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              LinkField(
                controller: _link,
                autofocus: true,
                enabled: !state.isSending,
                isValid: state.link != null,
                errorText: linkError == null ? null : domainErrorText(linkError, now: now),
                onChanged: (text) => bloc.add(LinkChanged(text)),
              ),
              if (state.link case final link?) ...[
                const SizedBox(height: 12),
                _RecognizedVideo(link: link, isSending: state.isSending),
              ],
              const SizedBox(height: 12),
              if (state.remaining case final remaining?)
                _DailyQuota(
                  remaining: remaining,
                  limitText: limitError == null ? null : domainErrorText(limitError, now: now),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpace.screen,
                8,
                AppSpace.screen,
                10 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: PrimaryButton(
                label: state.isSending ? 'Šaljemo…' : 'Analiziraj video',
                size: ButtonSize.xl,
                expanded: true,
                isBusy: state.isSending,
                onPressed: state.canSubmit ? () => bloc.add(const LinkSubmitted()) : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The green block: R1 passed, this is the video we understood from the link.
class _RecognizedVideo extends StatelessWidget {
  const _RecognizedVideo({required this.link, required this.isSending});

  final VideoLink link;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.statusColors.saved;
    return Container(
      padding: const EdgeInsets.all(AppSpace.insideCard),
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(platformText(link.platform), style: theme.textTheme.titleSmall)),
              AppIcon(AppIcons.check, size: 16, color: colors.foreground),
              const SizedBox(width: 4),
              Text('Video je prepoznat', style: theme.textTheme.labelMedium?.copyWith(color: colors.foreground)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isSending
                ? 'Šaljemo link na analizu…'
                : 'Analiza obično traje manje od minut. Možeš da zatvoriš aplikaciju.',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// R2: "Još 17 od 20", and the mustard block when nothing is left.
class _DailyQuota extends StatelessWidget {
  const _DailyQuota({required this.remaining, required this.limitText});

  final int remaining;
  final String? limitText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOut = limitText != null;
    return Container(
      padding: const EdgeInsets.all(AppSpace.insideCard),
      decoration: BoxDecoration(
        color: isOut ? theme.colorScheme.secondaryContainer : theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Analize danas', style: theme.textTheme.labelMedium)),
              Text('Još $remaining od $dailyAnalysisLimit', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: remaining / dailyAnalysisLimit, minHeight: 6),
          const SizedBox(height: 8),
          Text(
            limitText ?? 'Svaki poslat link troši jednu analizu, i kad je video već analiziran.',
            style: theme.textTheme.labelMedium?.copyWith(
              color: isOut ? theme.colorScheme.onSecondaryContainer : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
