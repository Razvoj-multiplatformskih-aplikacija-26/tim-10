import 'package:domain/domain.dart';

import 'ports/review_queue_repository.dart';

/// The editor's queue: every proposal waiting for a decision.
final class LoadReviewQueue {
  const LoadReviewQueue({required this.queue});

  final ReviewQueueRepository queue;

  Future<List<ReviewItem>> call() => queue.pending();
}
