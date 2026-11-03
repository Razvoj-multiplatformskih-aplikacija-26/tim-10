import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'review_queue_event.dart';
part 'review_queue_state.dart';

/// The editor's queue: loads the proposals, shows one of four states and keeps the cursor and the open panel.
///
/// The cursor and the panel live here, not in a widget: narrowing the window replaces the table with a list, Flutter
/// throws away the table's `State`, and the selection must survive that.
final class ReviewQueueBloc extends Bloc<ReviewQueueEvent, ReviewQueueState> {
  ReviewQueueBloc({required this.loadQueue, required this.editor}) : super(const ReviewQueueLoading()) {
    on<ReviewQueueRequested>(_onRequested);
    on<ReviewCursorMoved>(_onCursorMoved);
    on<ReviewCursorActivated>(_onCursorActivated);
    on<ReviewItemOpened>(_onItemOpened);
    on<ReviewPanelClosed>(_onPanelClosed);
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
      emit(items.isEmpty ? const ReviewQueueEmpty() : _opened(_loaded(items), event.selected));
    } on Exception catch (cause) {
      if (request != _request) return;
      emit(ReviewQueueFailure(cause));
    }
  }

  /// The panel follows the cursor: with the panel open, the arrows show the next proposal.
  void _onCursorMoved(ReviewCursorMoved event, Emitter<ReviewQueueState> emit) {
    final current = state;
    if (current is ReviewQueueLoaded) emit(current.withCursor(current.cursor + event.delta));
  }

  void _onCursorActivated(ReviewCursorActivated event, Emitter<ReviewQueueState> emit) {
    final current = state;
    if (current is ReviewQueueLoaded) emit(current.withPanel(isOpen: true));
  }

  void _onItemOpened(ReviewItemOpened event, Emitter<ReviewQueueState> emit) {
    final current = state;
    if (current is ReviewQueueLoaded) emit(_opened(current, event.id));
  }

  void _onPanelClosed(ReviewPanelClosed event, Emitter<ReviewQueueState> emit) {
    final current = state;
    if (current is ReviewQueueLoaded) emit(current.withPanel(isOpen: false));
  }

  /// The same queue with the panel on [id]. An id that is not in the queue (an old link) closes the panel.
  ReviewQueueLoaded _opened(ReviewQueueLoaded queue, EntryId? id) {
    final index = queue.items.indexWhere((item) => item.id == id);
    return index < 0 ? queue.withPanel(isOpen: false) : queue.withCursor(index).withPanel(isOpen: true);
  }

  ReviewQueueLoaded _loaded(List<ReviewItem> items) =>
      ReviewQueueLoaded(items, canDecide: AccessPolicy.canDecide(editor));
}
