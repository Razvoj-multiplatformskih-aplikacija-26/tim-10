import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/review_queue_repository.dart';

/// "Objavi": find the proposal, let the domain decide (`publishEntry`), store the result.
final class PublishProposal {
  const PublishProposal({required this.queue, required this.clock});

  final ReviewQueueRepository queue;
  final Clock clock;

  /// In KT1 the catalog record keeps the id of the entry; from KT2 the server gives the record its own id.
  Future<Result<Entry>> call(EntryId id, {required User by}) async {
    final entry = await queue.find(id);
    if (entry == null) return const Failure(NotFound());
    return switch (publishEntry(entry, by: by, now: clock.now(), catalogId: entry.id)) {
      Failure(:final error) => Failure(error),
      Success(:final value) => Success(await queue.decide(value)),
    };
  }
}
