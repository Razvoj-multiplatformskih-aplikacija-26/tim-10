import 'package:flutter/painting.dart';

/// Every color of the "enamelware" palette. Names match the Figma variables (`boja/…`).
///
/// No other file creates a `Color(0x…)`; widgets pick a color from here.
abstract final class AppColors {
  /// Screen background.
  static const enamel = Color(0xFFF4F6F3);

  /// Cards, fields and the bottom navigation.
  static const card = Color(0xFFFFFFFF);

  /// Main text, icons and the primary button.
  static const ink = Color(0xFF18202E);

  /// Secondary text.
  static const ink2 = Color(0xFF5A6475);

  /// Borders.
  static const line = Color(0xFFDCE1E6);

  /// Segment background and loading skeletons.
  static const track = Color(0xFFE6EAE8);

  /// Card rim while the entry type is not known yet.
  static const rimNeutral = Color(0xFFAEB6C2);

  /// Recipe; "Nije uspelo" badge.
  static const tomato = Color(0xFFD7372A);
  static const tomatoSoft = Color(0xFFFBE4E1);

  /// Restaurant; processing progress.
  static const cobalt = Color(0xFF2340A8);
  static const cobaltSoft = Color(0xFFE2E8FA);

  /// Personal layer and "Za pregled".
  static const mustard = Color(0xFFE5AC1F);
  static const mustardSoft = Color(0xFFFBEFC9);
  static const mustardInk = Color(0xFF5E4300);

  /// "Sačuvano".
  static const pea = Color(0xFF2F7A43);
  static const peaSoft = Color(0xFFE0F0E3);

  /// "Čeka urednika".
  static const plum = Color(0xFF5B3F99);
  static const plumSoft = Color(0xFFECE6F7);

  /// Error text.
  static const maroon = Color(0xFF8F1D15);

  // Not Figma variables, but used by the drafts in docs/dizajn/nacrti.

  /// Text and icons on an `ink` background.
  static const onInk = Color(0xFFFFFFFF);

  /// Border of mustard surfaces (highlighted chip, review banner).
  static const mustardLine = Color(0xFFEBCB73);
}
