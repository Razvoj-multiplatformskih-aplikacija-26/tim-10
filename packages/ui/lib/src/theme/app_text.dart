import 'package:flutter/painting.dart';

/// Text styles from the typography table in `docs/dizajn/ekrani.md` (section 2).
///
/// Styles carry no color, so they inherit it from the theme; a widget adds a color with `copyWith`.
///
/// Every style sets `height` and `letterSpacing`. Otherwise it would inherit the Material 3 defaults (line
/// height 1.33–1.5, letter spacing 0.25–0.5 px), because `ThemeData` merges our text theme into Material's, and
/// text would come out taller and wider than in the drafts.
abstract final class AppText {
  static const fontFamily = 'BricolageGrotesque';

  /// The font's own line height, what the drafts get from CSS `line-height: normal`. Used where the
  /// typography table gives no line height.
  static const normalHeight = 1.2;

  /// The font is declared in this package's pubspec, so apps must name the package to find it.
  static const package = 'ui';

  /// "Naslov ekrana": 34 / 800 / 100 %, letter spacing −3.5 %.
  static const screenTitle = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -0.035 * 34,
  );

  /// "Naslov stanja" (empty and error states): 23 / 800 / 120 %.
  static const stateTitle = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 23,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.02 * 23,
  );

  /// "Naslov kartice": 18 / 700 / 120 %.
  static const cardTitle = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.01 * 18,
  );

  /// "Telo": 15 / 400 / 145 %.
  static const body = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0,
  );

  /// "Dugme": 14 / 700.
  static const button = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: normalHeight,
    letterSpacing: 0,
  );

  /// "Segment": 14 / 600.
  static const segment = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: normalHeight,
    letterSpacing: 0,
  );

  /// "Činjenica" (time, kcal, neighbourhood on a card): 13 / 500.
  static const fact = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: normalHeight,
    letterSpacing: 0,
  );

  /// Filter chip: 13 / 600.
  static const chip = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: normalHeight,
    letterSpacing: 0,
  );

  /// "Bedž": 12 / 700.
  static const badge = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: normalHeight,
    letterSpacing: 0,
  );

  /// Type label and "1 od 3" on a card: 12.5 / 700.
  static const label = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    height: normalHeight,
    letterSpacing: 0,
  );

  /// "Autor": 12.5 / 400.
  static const author = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: normalHeight,
    letterSpacing: 0,
  );

  /// "Tab" in the bottom navigation: 11 / 600.
  static const tab = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: normalHeight,
    letterSpacing: 0,
  );

  /// "Oznaka izvora" on a thumbnail (Instagram, TikTok, Ručno): 9.5 / 700.
  static const sourceLabel = TextStyle(
    fontFamily: fontFamily,
    package: package,
    fontSize: 9.5,
    fontWeight: FontWeight.w700,
    height: normalHeight,
    letterSpacing: 0.01 * 9.5,
  );
}
