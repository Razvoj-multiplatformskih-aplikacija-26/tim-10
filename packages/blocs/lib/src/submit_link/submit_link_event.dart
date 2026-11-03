part of 'submit_link_bloc.dart';

sealed class SubmitLinkEvent {
  const SubmitLinkEvent();
}

/// The form was opened: load the daily counter.
final class SubmitLinkOpened extends SubmitLinkEvent {
  const SubmitLinkOpened();
}

/// The user typed or pasted into the link field.
final class LinkChanged extends SubmitLinkEvent {
  const LinkChanged(this.text);

  final String text;
}

/// The user tapped "Analiziraj video".
final class LinkSubmitted extends SubmitLinkEvent {
  const LinkSubmitted();
}

/// The screen has shown the outcome; the Bloc can forget it.
final class SubmitLinkNoticeAcknowledged extends SubmitLinkEvent {
  const SubmitLinkNoticeAcknowledged();
}
