import 'package:domain/domain.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// What a card shows as its type. `unknown` is a video whose analysis has not finished yet.
///
/// Temporary: once the domain exists, the type comes from the entry's content.
enum EntryCardKind { recipe, restaurant, unknown }

/// The kind of an entry from its content; while the analysis runs there is no content yet.
EntryCardKind cardKindOf(EntryContent? content) => switch (content) {
  RecipeContent() => EntryCardKind.recipe,
  RestaurantContent() => EntryCardKind.restaurant,
  null => EntryCardKind.unknown,
};

/// Colors of the entry types (card rim and type label), as a theme extension.
@immutable
class EntryKindColors extends ThemeExtension<EntryKindColors> {
  const EntryKindColors({required this.recipe, required this.restaurant, required this.unknown});

  static const light = EntryKindColors(
    recipe: AppColors.tomato,
    restaurant: AppColors.cobalt,
    unknown: AppColors.rimNeutral,
  );

  final Color recipe;
  final Color restaurant;

  /// Only for the rim; it is too light for text.
  final Color unknown;

  Color rimFor(EntryCardKind kind) => switch (kind) {
    EntryCardKind.recipe => recipe,
    EntryCardKind.restaurant => restaurant,
    EntryCardKind.unknown => unknown,
  };

  @override
  EntryKindColors copyWith({Color? recipe, Color? restaurant, Color? unknown}) {
    return EntryKindColors(
      recipe: recipe ?? this.recipe,
      restaurant: restaurant ?? this.restaurant,
      unknown: unknown ?? this.unknown,
    );
  }

  @override
  EntryKindColors lerp(EntryKindColors? other, double t) {
    if (other == null) return this;
    return EntryKindColors(
      recipe: Color.lerp(recipe, other.recipe, t)!,
      restaurant: Color.lerp(restaurant, other.restaurant, t)!,
      unknown: Color.lerp(unknown, other.unknown, t)!,
    );
  }
}

extension EntryKindColorsX on ThemeData {
  EntryKindColors get kindColors => extension<EntryKindColors>() ?? EntryKindColors.light;
}
