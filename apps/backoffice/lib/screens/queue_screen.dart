import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
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
  @override
  void initState() {
    super.initState();
    context.read<ReviewQueueBloc>().add(ReviewQueueRequested(selected: widget.selected));
  }

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
      appBar: AppBar(title: const Text('Red predloga')),
      body: BlocConsumer<ReviewQueueBloc, ReviewQueueState>(
        listener: _showNotice,
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
            child: EmptyState(title: 'Red je prazan', message: 'Nijedan predlog ne čeka odluku urednika.'),
          ),
          ReviewQueueLoaded() => _QueueBody(state: state, onPublish: _publish, onReject: _reject),
        },
      ),
    );
  }
}

/// The table and, when a proposal is open, the panel next to it.
class _QueueBody extends StatelessWidget {
  const _QueueBody({required this.state, required this.onPublish, required this.onReject});

  final ReviewQueueLoaded state;
  final ValueChanged<EntryId> onPublish;
  final ValueChanged<EntryId> onReject;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ReviewQueueBloc>();
    final now = context.read<AppDependencies>().clock.now();
    final canAct = state.canDecide && !state.isBusy;
    return Column(
      children: [
        SizedBox(height: 4, child: state.isBusy ? const LinearProgressIndicator() : null),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: QueueTable(state: state, now: now, onOpen: (id) => bloc.add(ReviewItemOpened(id))),
              ),
              if (state.isPanelOpen) ...[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 380,
                  child: ReviewDetailPanel(
                    item: state.current,
                    now: now,
                    onClose: () => bloc.add(const ReviewPanelClosed()),
                    onPublish: canAct ? () => onPublish(state.current.id) : null,
                    onReject: canAct ? () => onReject(state.current.id) : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
