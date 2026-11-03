import 'package:blocs/blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';

/// Shows the outcome of an action as one SnackBar and acknowledges it, so it does not show again.
///
/// It sits on the library, which stays alive under the detail screen, so the message appears on both.
class EntryNotices extends StatelessWidget {
  const EntryNotices({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<EntriesBloc, EntriesState>(
      listenWhen: (previous, current) => current is EntriesLoaded && current.notice != null,
      listener: _show,
      child: child,
    );
  }

  void _show(BuildContext context, EntriesState state) {
    if (state is! EntriesLoaded) return;
    final notice = state.notice;
    if (notice == null) return;

    final bloc = context.read<EntriesBloc>();
    final now = context.read<AppDependencies>().clock.now();
    final (text, retry) = switch (notice) {
      EntryActionSucceeded(:final action) => (_successText(action), null),
      EntryActionRejected(:final error) => (domainErrorText(error, now: now), null),
      EntryActionFailed(:final action, :final id) => ('Nije sačuvano.', EntryActionRequested(action, id)),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: retry == null ? null : SnackBarAction(label: 'Pokušaj ponovo', onPressed: () => bloc.add(retry)),
        ),
      );
    bloc.add(const EntriesNoticeAcknowledged());
  }

  String _successText(EntryAction action) => switch (action) {
    EntryAction.save => 'Sačuvano u biblioteci.',
    EntryAction.propose => 'Predlog je poslat uredniku.',
    EntryAction.retry => 'Video je ponovo poslat na analizu.',
    EntryAction.delete => 'Unos je obrisan.',
  };
}
