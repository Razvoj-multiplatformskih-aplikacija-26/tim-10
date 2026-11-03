import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
import '../router.dart';
import '../shortcuts.dart';
import '../widgets/queue_list.dart';
import '../widgets/queue_menu.dart';
import '../widgets/queue_skeleton.dart';
import '../widgets/queue_table.dart';
import '../widgets/reject_dialog.dart';
import '../widgets/review_detail_panel.dart';

/// The editor's main screen: the queue of proposals. It only draws the state of the Bloc and sends events.
class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key, this.selected});

  /// The proposal named in the address (`/queue?entry=p-3`).
  final EntryId? selected;

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  // Above the table and the list, so the keyboard keeps working when one replaces the other.
  final _focus = FocusNode(debugLabel: 'queue');

  @override
  void initState() {
    super.initState();
    context.read<ReviewQueueBloc>().add(ReviewQueueRequested(selected: widget.selected));
  }

  /// From the address to the Bloc: a pasted link, or the back button of the browser.
  @override
  void didUpdateWidget(QueueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = widget.selected;
    if (selected == oldWidget.selected) return;
    context.read<ReviewQueueBloc>().add(selected == null ? const ReviewPanelClosed() : ReviewItemOpened(selected));
  }

  /// From the Bloc to the address, so the open proposal survives a refresh of the page.
  void _syncAddress(BuildContext context, ReviewQueueState state) {
    final selected = switch (state) {
      ReviewQueueLoaded(:final selectedId) => selectedId,
      ReviewQueueEmpty() => null,
      ReviewQueueLoading() || ReviewQueueFailure() => widget.selected,
    };
    if (selected != widget.selected) context.go(queueLocation(selected));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// The queue, when it is on the screen. Shortcuts do nothing during loading and in the empty state.
  ReviewQueueLoaded? get _queue => switch (context.read<ReviewQueueBloc>().state) {
    final ReviewQueueLoaded queue => queue,
    _ => null,
  };

  bool get _canDecide {
    final queue = _queue;
    return queue != null && queue.canDecide && !queue.isBusy;
  }

  void _open(EntryId id) {
    _focus.requestFocus(); // after a click the arrows must still work
    context.read<ReviewQueueBloc>().add(ReviewItemOpened(id));
  }

  Map<Type, Action<Intent>> _actions() {
    final bloc = context.read<ReviewQueueBloc>();
    return {
      MoveCursorIntent: GuardedAction<MoveCursorIntent>(
        enabled: () => _queue != null,
        onInvoke: (intent) => bloc.add(ReviewCursorMoved(intent.delta)),
      ),
      OpenCursorIntent: GuardedAction<OpenCursorIntent>(
        enabled: () => _queue != null && _focus.hasPrimaryFocus,
        onInvoke: (_) => bloc.add(const ReviewCursorActivated()),
      ),
      ClosePanelIntent: GuardedAction<ClosePanelIntent>(
        enabled: () => _queue?.isPanelOpen ?? false,
        onInvoke: (_) => bloc.add(const ReviewPanelClosed()),
      ),
      PublishIntent: GuardedAction<PublishIntent>(
        enabled: () => _canDecide,
        onInvoke: (_) => _publish(_queue!.current.id),
      ),
      RejectIntent: GuardedAction<RejectIntent>(
        enabled: () => _canDecide,
        onInvoke: (_) => _reject(_queue!.current.id),
      ),
      ShowShortcutsIntent: CallbackAction<ShowShortcutsIntent>(onInvoke: (_) => _showShortcuts()),
    };
  }

  Future<void> _showShortcuts() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Prečice'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (key, meaning) in queueShortcutsHelp)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SizedBox(width: 64, child: Text(key, style: Theme.of(context).textTheme.titleMedium)),
                  Text(meaning, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  void _publish(EntryId id) => context.read<ReviewQueueBloc>().add(ProposalPublishRequested(id));

  Future<void> _reject(EntryId id) async {
    final bloc = context.read<ReviewQueueBloc>();
    final reason = await showRejectDialog(context, now: context.read<AppDependencies>().clock.now());
    if (reason != null) bloc.add(ProposalRejectRequested(id, reason));
  }

  /// A notice is a one-time message: it is shown as a SnackBar and then acknowledged, so it does not show again.
  void _showNotice(BuildContext context, ReviewQueueState state) {
    final notice = switch (state) {
      ReviewQueueLoaded(:final notice) || ReviewQueueEmpty(:final notice) => notice,
      ReviewQueueLoading() || ReviewQueueFailure() => null,
    };
    if (notice == null) return;

    final bloc = context.read<ReviewQueueBloc>();
    final now = context.read<AppDependencies>().clock.now();
    final (text, retry) = switch (notice) {
      ReviewActionSucceeded(decision: ReviewDecision.publish) => ('Objavljeno u katalogu.', null),
      ReviewActionSucceeded(decision: ReviewDecision.reject) => ('Predlog je odbijen.', null),
      ReviewActionRefused(:final error) => (domainErrorText(error, now: now), null),
      ReviewActionFailed(:final request) => ('Nije sačuvano.', request),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: retry == null ? null : SnackBarAction(label: 'Pokušaj ponovo', onPressed: () => bloc.add(retry)),
        ),
      );
    bloc.add(const ReviewNoticeAcknowledged());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Red predloga'),
        actions: [
          QueueMenu(
            onRefresh: () => context.read<ReviewQueueBloc>().add(ReviewQueueRequested(selected: widget.selected)),
            onShowShortcuts: _showShortcuts,
          ),
        ],
      ),
      body: Shortcuts(
        shortcuts: queueShortcuts,
        child: Actions(
          actions: _actions(),
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            child: BlocConsumer<ReviewQueueBloc, ReviewQueueState>(
              listener: (context, state) {
                _syncAddress(context, state);
                _showNotice(context, state);
              },
              builder: (context, state) => switch (state) {
                ReviewQueueLoading() => const QueueSkeleton(),
                ReviewQueueFailure() => Center(
                  child: ErrorState(
                    title: 'Predlozi nisu učitani',
                    message: 'Nismo uspeli da dohvatimo red predloga.',
                    onRetry: () => context.read<ReviewQueueBloc>().add(ReviewQueueRequested(selected: widget.selected)),
                  ),
                ),
                ReviewQueueEmpty() => const Center(
                  child: EmptyState(
                    title: 'Red je prazan. Svaka čast!',
                    message: 'Nijedan predlog ne čeka odluku urednika.',
                  ),
                ),
                ReviewQueueLoaded() => _QueueBody(
                  state: state,
                  focusNode: _focus,
                  onOpen: _open,
                  onPublish: _publish,
                  onReject: _reject,
                ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Below this width the table becomes a list and the side panel moves under it.
const _wideFrom = 840.0;

/// The proposals and, when one is open, its panel. The cursor and the panel live in the Bloc, above this
/// `LayoutBuilder`, so changing the width of the window never loses the selection.
class _QueueBody extends StatelessWidget {
  const _QueueBody({
    required this.state,
    required this.focusNode,
    required this.onOpen,
    required this.onPublish,
    required this.onReject,
  });

  final ReviewQueueLoaded state;
  final FocusNode focusNode;
  final ValueChanged<EntryId> onOpen;
  final ValueChanged<EntryId> onPublish;
  final ValueChanged<EntryId> onReject;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReviewQueueBloc>();
    final now = context.read<AppDependencies>().clock.now();
    final canAct = state.canDecide && !state.isBusy;
    final panel = ReviewDetailPanel(
      item: state.current,
      now: now,
      onClose: () => bloc.add(const ReviewPanelClosed()),
      onPublish: canAct ? () => onPublish(state.current.id) : null,
      onReject: canAct ? () => onReject(state.current.id) : null,
    );

    return Column(
      children: [
        SizedBox(height: 4, child: state.isBusy ? const LinearProgressIndicator() : null),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < _wideFrom) {
                return Column(
                  children: [
                    Expanded(
                      child: QueueList(state: state, now: now, focusNode: focusNode, onOpen: onOpen),
                    ),
                    if (state.isPanelOpen) ...[
                      const Divider(height: 1),
                      SizedBox(height: constraints.maxHeight * 0.6, child: panel),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: QueueTable(state: state, now: now, focusNode: focusNode, onOpen: onOpen),
                  ),
                  if (state.isPanelOpen) ...[const VerticalDivider(width: 1), SizedBox(width: 380, child: panel)],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
