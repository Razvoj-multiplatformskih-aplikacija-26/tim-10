part of 'entries_bloc.dart';

sealed class EntriesEvent {
  const EntriesEvent();
}

/// The library was opened, or the user tapped "Pokušaj ponovo": both load the entries the same way.
final class EntriesRequested extends EntriesEvent {
  const EntriesRequested();
}

/// What the owner can do with an entry; each is one button and one transition.
enum EntryAction { save, propose, retry, delete }

/// The user tapped "Sačuvaj", "Predloži za katalog", "Pokušaj ponovo" or confirmed "Obriši".
final class EntryActionRequested extends EntriesEvent {
  const EntryActionRequested(this.action, this.id);

  final EntryAction action;
  final EntryId id;
}

/// The user picked a segment: Sve, Recepti or Restorani.
final class EntriesKindFilterChanged extends EntriesEvent {
  const EntriesKindFilterChanged(this.kind);

  final KindFilter kind;
}

/// The user tapped a status chip. Tapping the selected chip again shows all states.
final class EntriesStatusFilterToggled extends EntriesEvent {
  const EntriesStatusFilterToggled(this.chip);

  final StatusFilter chip;
}

/// The screen has shown the notice (a SnackBar); the Bloc can forget it.
final class EntriesNoticeAcknowledged extends EntriesEvent {
  const EntriesNoticeAcknowledged();
}
