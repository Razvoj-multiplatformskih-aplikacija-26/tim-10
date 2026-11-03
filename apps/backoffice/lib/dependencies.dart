import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_review_queue.dart';
import 'data/seed.dart';

/// The one place that chooses the implementations of the ports.
///
/// Replacing the fake with the server in KT2 changes only this file; the screens stay the same.
final class AppDependencies {
  AppDependencies._({required this.queue, required this.clock, required this.editor, this.fakeQueue});

  factory AppDependencies.fake({
    Clock clock = const SystemClock(),
    Duration latency = const Duration(milliseconds: 600),
  }) {
    final queue = FakeReviewQueue(seed: demoEntries(clock.now()), latency: latency);
    return AppDependencies._(queue: queue, clock: clock, editor: demoEditor, fakeQueue: queue);
  }

  final ReviewQueueRepository queue;
  final Clock clock;
  final User editor;

  /// The fake behind [queue], for the debug buttons. `null` once the app talks to a real server.
  final FakeReviewQueue? fakeQueue;

  ReviewQueueBloc reviewQueueBloc() => ReviewQueueBloc(
    loadQueue: LoadReviewQueue(queue: queue),
    publish: PublishProposal(queue: queue, clock: clock),
    reject: RejectProposal(queue: queue, clock: clock),
    editor: editor,
  );
}
