part of 'review_queue_bloc.dart';

sealed class ReviewQueueEvent {
  const ReviewQueueEvent();
}

/// The queue was opened, or the editor tapped "Pokušaj ponovo": both load the proposals the same way.
final class ReviewQueueRequested extends ReviewQueueEvent {
  const ReviewQueueRequested();
}
