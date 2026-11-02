import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text.dart';
import 'entry_kind_colors.dart';
import 'status_colors.dart';

/// The one place where the Material theme is built, only from `AppColors`, `AppText` and `AppRadius`.
///
/// Widgets read colors from here: general ones from `colorScheme`, state and type colors from the
/// `StatusColors` and `EntryKindColors` extensions. They never use `AppColors` directly.
///
/// In our scheme `primary` is ink (main buttons), `secondary` is mustard (the personal layer) and
/// `onSurfaceVariant` is ink2 (secondary text). A dark theme comes after KT1.
abstract final class AppTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.onInk,
      primaryContainer: AppColors.track,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.mustard,
      onSecondary: AppColors.mustardInk,
      secondaryContainer: AppColors.mustardSoft,
      onSecondaryContainer: AppColors.mustardInk,
      tertiary: AppColors.cobalt,
      onTertiary: AppColors.onInk,
      tertiaryContainer: AppColors.cobaltSoft,
      onTertiaryContainer: AppColors.cobalt,
      error: AppColors.tomato,
      onError: AppColors.onInk,
      errorContainer: AppColors.tomatoSoft,
      onErrorContainer: AppColors.maroon,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.ink2,
      surfaceContainerLowest: AppColors.card,
      surfaceContainerLow: AppColors.card,
      surfaceContainer: AppColors.card,
      surfaceContainerHigh: AppColors.card,
      surfaceContainerHighest: AppColors.track,
      outline: AppColors.line,
      outlineVariant: AppColors.line,
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.onInk,
      inversePrimary: AppColors.mustard,
      shadow: AppColors.ink,
      scrim: AppColors.ink,
      surfaceTint: Colors.transparent,
    );

    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button));
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      extensions: const [StatusColors.light, EntryKindColors.light],
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.enamel,
      canvasColor: AppColors.enamel,
      fontFamily: AppText.fontFamily,
      package: AppText.package,
      textTheme: const TextTheme(
        headlineLarge: AppText.screenTitle,
        headlineSmall: AppText.stateTitle,
        titleMedium: AppText.cardTitle,
        titleSmall: AppText.segment,
        bodyLarge: AppText.body,
        bodyMedium: AppText.body,
        bodySmall: AppText.author,
        labelLarge: AppText.button,
        labelMedium: AppText.fact,
        labelSmall: AppText.badge,
      ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.enamel,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.onInk,
          disabledBackgroundColor: AppColors.track,
          disabledForegroundColor: AppColors.ink2,
          textStyle: AppText.button,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.5),
          textStyle: AppText.button,
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.ink, textStyle: AppText.button, shape: buttonShape),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: AppText.body.copyWith(color: AppColors.ink2),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.ink, width: 2)),
        errorBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.tomato, width: 2)),
        focusedErrorBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: AppColors.tomato, width: 2)),
        errorStyle: AppText.fact.copyWith(color: AppColors.maroon),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        actionTextColor: AppColors.mustard,
        contentTextStyle: AppText.body.copyWith(fontSize: 14, height: 1.35, color: AppColors.onInk),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.field)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
        titleTextStyle: AppText.stateTitle.copyWith(color: AppColors.ink),
        contentTextStyle: AppText.body.copyWith(color: AppColors.ink2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: AppColors.card),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.cobalt,
        linearTrackColor: AppColors.cobaltSoft,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.ink,
        selectionColor: AppColors.cobaltSoft,
        selectionHandleColor: AppColors.cobalt,
      ),
    );
  }
}
