import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'submit_link_event.dart';
part 'submit_link_state.dart';

/// The form "Dodaj video" (M-05): R1 while typing, R2 before sending, then the link goes to the repository.
///
/// A local Bloc: the screen creates it when the form opens and it closes with the form.
final class SubmitLinkBloc extends Bloc<SubmitLinkEvent, SubmitLinkState> {
  SubmitLinkBloc({required this.loadMyEntries, required this.submitLink, required this.user, required this.clock})
    : super(const SubmitLinkState()) {
    on<SubmitLinkOpened>(_onOpened);
    on<LinkChanged>(_onLinkChanged);
    on<LinkSubmitted>(_onLinkSubmitted);
    on<SubmitLinkNoticeAcknowledged>(_onNoticeAcknowledged);
  }

  final LoadMyEntries loadMyEntries;
  final SubmitLink submitLink;
  final User user;
  final Clock clock;

  /// Loads the counter "Još 17 od 20". If it cannot be loaded, the form still works without it; the repository
  /// checks the limit anyway when the link is sent.
  Future<void> _onOpened(SubmitLinkOpened event, Emitter<SubmitLinkState> emit) async {
    try {
      final mine = await loadMyEntries(user);
      switch (checkDailyLimit(mine, now: clock.now())) {
        case Success(:final value):
          emit(state.withQuota(remaining: value));
        case Failure(:final error):
          emit(state.withQuota(remaining: 0, limitError: error));
      }
    } on Exception {
      return;
    }
  }

  /// R1 on every change. An empty field shows no error: the user has not typed anything wrong yet.
  void _onLinkChanged(LinkChanged event, Emitter<SubmitLinkState> emit) {
    if (event.text.trim().isEmpty) {
      emit(state.withInput(event.text));
      return;
    }
    switch (VideoLink.parse(event.text)) {
      case Success(:final value):
        emit(state.withInput(event.text, link: value));
      case Failure(:final error):
        emit(state.withInput(event.text, linkError: error));
    }
  }

  Future<void> _onLinkSubmitted(LinkSubmitted event, Emitter<SubmitLinkState> emit) async {
    final link = state.link;
    if (link == null || !state.canSubmit) return;
    emit(state.sending());

    try {
      switch (await submitLink(link, by: user)) {
        case Success(:final value):
          emit(state.withNotice(SubmitSucceeded(value)));
        case Failure(:final error):
          emit(state.withNotice(SubmitRejected(error)));
      }
    } on Exception catch (cause) {
      emit(state.withNotice(SubmitFailed(cause)));
    }
  }

  void _onNoticeAcknowledged(SubmitLinkNoticeAcknowledged event, Emitter<SubmitLinkState> emit) {
    if (state.notice != null) emit(state.withNotice(null));
  }
}
