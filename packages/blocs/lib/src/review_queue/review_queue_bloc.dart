import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'review_queue_event.dart';
part 'review_queue_state.dart';

/// The editor's queue: loads the proposals and shows one of four states.
final class ReviewQueueBloc extends Bloc<ReviewQueueEvent, ReviewQueueState> {
  ReviewQueueBloc({required this.loadQueue, required this.editor}) : super(const ReviewQueueLoading()) {
    on<ReviewQueueRequested>(_onRequested);
  }

  final LoadReviewQueue loadQueue;

  /// The signed-in editor. In KT1 a fixed demo user; from KT2 the one who logged in.
  final User editor;

  /// Every load gets a number; an answer to an older load is dropped.
  int _request = 0;

  Future<void> _onRequested(ReviewQueueRequested event, Emitter<ReviewQueueState> emit) async {
    final request = ++_request;
    emit(const ReviewQueueLoading());
    try {
      final items = await loadQueue();
      if (request != _request) return;
      emit(items.isEmpty ? const ReviewQueueEmpty() : _loaded(items));
    } on Exception catch (cause) {
      if (request != _request) return;
      emit(ReviewQueueFailure(cause));
    }
  }

  ReviewQueueLoaded _loaded(List<ReviewItem> items) =>
      ReviewQueueLoaded(items, canDecide: AccessPolicy.canDecide(editor));
}
