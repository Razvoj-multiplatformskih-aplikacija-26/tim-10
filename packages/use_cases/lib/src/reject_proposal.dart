import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/review_queue_repository.dart';

/// "Odbij": find the proposal, let the domain decide (`rejectEntry`), store the result.
///
/// The reason has already passed `RejectionReason.parse` (R8) in the dialog.
final class RejectProposal {
  const RejectProposal({required this.queue, required this.clock});

  final ReviewQueueRepository queue;
  final Clock clock;

  Future<Result<Entry>> call(EntryId id, {required User by, required RejectionReason reason}) async {
    final entry = await queue.find(id);
    if (entry == null) return const Failure(NotFound());
    return switch (rejectEntry(entry, by: by, now: clock.now(), reason: reason)) {
      Failure(:final error) => Failure(error),
      Success(:final value) => Success(await queue.decide(value)),
    };
  }
}
