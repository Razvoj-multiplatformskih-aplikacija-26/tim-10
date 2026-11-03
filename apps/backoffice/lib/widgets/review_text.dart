import 'package:domain/domain.dart';
import 'package:ui/ui.dart';

/// The name of a proposal in the table, the list and the panel.
String titleOf(EntryContent content) => switch (content) {
  RecipeContent(:final title) => title,
  RestaurantContent(:final name) => name,
};

/// The short line next to the name: where a restaurant is, how long a recipe takes.
String summaryOf(EntryContent content) => switch (content) {
  RecipeContent(:final prepTime, :final servings) =>
    prepTime == null ? '$servings porcije' : '${prepTime.inMinutes} min · $servings porcije',
  RestaurantContent(:final location, :final cuisine) => '${location.city} · $cuisine',
};

EntryCardKind kindOf(EntryContent content) => switch (content) {
  RecipeContent() => EntryCardKind.recipe,
  RestaurantContent() => EntryCardKind.restaurant,
};

/// "pre 40 min", "pre 3 h", "pre 2 dana".
String agoText(DateTime at, {required DateTime now}) {
  final age = now.difference(at);
  if (age.inMinutes < 60) return 'pre ${age.inMinutes} min';
  if (age.inHours < 24) return 'pre ${age.inHours} h';
  return age.inDays == 1 ? 'pre 1 dan' : 'pre ${age.inDays} dana';
}
