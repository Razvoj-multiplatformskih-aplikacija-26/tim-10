import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/ui.dart';

import '../dependencies.dart';
import '../widgets/queue_skeleton.dart';
import '../widgets/queue_table.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Red predloga')),
      body: BlocBuilder<ReviewQueueBloc, ReviewQueueState>(
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
          ReviewQueueLoaded() => QueueTable(
            state: state,
            now: context.read<AppDependencies>().clock.now(),
            onOpen: (id) => context.read<ReviewQueueBloc>().add(ReviewItemOpened(id)),
          ),
        },
      ),
    );
  }
}
