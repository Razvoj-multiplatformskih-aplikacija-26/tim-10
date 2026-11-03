import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// An Intent only names what the editor wants; the Action in the screen holds the code. The letters are not browser
// shortcuts, so the same keys work on the desktop and on the web.

final class MoveCursorIntent extends Intent {
  const MoveCursorIntent(this.delta);

  final int delta;
}

final class OpenCursorIntent extends Intent {
  const OpenCursorIntent();
}

final class ClosePanelIntent extends Intent {
  const ClosePanelIntent();
}

final class PublishIntent extends Intent {
  const PublishIntent();
}

final class RejectIntent extends Intent {
  const RejectIntent();
}

final class ShowShortcutsIntent extends Intent {
  const ShowShortcutsIntent();
}

final queueShortcuts = <ShortcutActivator, Intent>{
  const SingleActivator(LogicalKeyboardKey.arrowDown): const MoveCursorIntent(1),
  const SingleActivator(LogicalKeyboardKey.arrowUp): const MoveCursorIntent(-1),
  const SingleActivator(LogicalKeyboardKey.enter): const OpenCursorIntent(),
  const SingleActivator(LogicalKeyboardKey.escape): const ClosePanelIntent(),
  const SingleActivator(LogicalKeyboardKey.keyO): const PublishIntent(),
  const SingleActivator(LogicalKeyboardKey.keyX): const RejectIntent(),
  const CharacterActivator('?'): const ShowShortcutsIntent(),
};

/// The list shown by "Prečice": the key and what it does.
const queueShortcutsHelp = [
  ('↑ ↓', 'kretanje kroz red'),
  ('Enter', 'otvori predlog'),
  ('Esc', 'zatvori panel'),
  ('O', 'objavi'),
  ('X', 'odbij, uz razlog'),
  ('?', 'ove prečice'),
];

/// An action that is sometimes off. When [enabled] says no, the key goes on to the next listener, so Enter on a focused
/// button still presses that button.
final class GuardedAction<T extends Intent> extends CallbackAction<T> {
  GuardedAction({required this.enabled, required super.onInvoke});

  final bool Function() enabled;

  @override
  bool isEnabled(T intent) => enabled();
}
