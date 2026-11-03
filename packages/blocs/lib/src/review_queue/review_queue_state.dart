part of 'review_queue_bloc.dart';

/// The four states of the main screen (KT1): loading, failure with "Pokušaj ponovo", empty, data.
sealed class ReviewQueueState extends Equatable {
  const ReviewQueueState();
}

/// The screen shows empty rows.
final class ReviewQueueLoading extends ReviewQueueState {
  const ReviewQueueLoading();

  @override
  List<Object?> get props => [];
}

/// The proposals could not be loaded; the screen offers "Pokušaj ponovo".
final class ReviewQueueFailure extends ReviewQueueState {
  const ReviewQueueFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}

/// Nothing is waiting for a decision.
final class ReviewQueueEmpty extends ReviewQueueState {
  const ReviewQueueEmpty();

  @override
  List<Object?> get props => [];
}

final class ReviewQueueLoaded extends ReviewQueueState {
  const ReviewQueueLoaded(this.items, {this.canDecide = false});

  /// The proposals, oldest first.
  final List<ReviewItem> items;

  /// Whether the signed-in user may publish and reject. The domain answers; the screen only draws it.
  final bool canDecide;

  @override
  List<Object?> get props => [items, canDecide];

  @override
  String toString() => 'ReviewQueueLoaded(${items.length} items)';
}
