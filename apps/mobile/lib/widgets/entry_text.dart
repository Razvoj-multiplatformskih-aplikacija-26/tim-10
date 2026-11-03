import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/ui.dart';

// What an entry looks like in words and pictures. No rules here: only text for what the domain already decided.

String platformText(VideoPlatform platform) => switch (platform) {
  VideoPlatform.instagram => 'Instagram',
  VideoPlatform.tiktok => 'TikTok',
};

String priceText(PriceRange price) => switch (price) {
  PriceRange.budget => '€',
  PriceRange.moderate => '€€',
  PriceRange.expensive => '€€€',
  PriceRange.luxury => '€€€€',
};

/// "2 porcije", "5 porcija", "1 porcija".
String servingsText(int servings) => switch (servings) {
  1 => '1 porcija',
  2 || 3 || 4 => '$servings porcije',
  _ => '$servings porcija',
};

/// "paradajz, 400 g" or just "so" for "to taste".
String ingredientText(Ingredient ingredient) => switch (ingredient.quantity) {
  null => ingredient.name,
  final quantity => '${ingredient.name}, ${_amountText(quantity.amount)} ${_unitText(quantity.unit)}',
};

/// A whole number without ".0"; on the web and on the phone the same text.
String _amountText(double amount) => amount == amount.roundToDouble() ? amount.toInt().toString() : amount.toString();

String _unitText(Unit unit) => switch (unit) {
  Unit.g => 'g',
  Unit.kg => 'kg',
  Unit.ml => 'ml',
  Unit.l => 'l',
  Unit.piece => 'kom',
  Unit.tbsp => 'kaš.',
  Unit.tsp => 'kašič.',
  Unit.cup => 'šolja',
};

/// The name on the card and at the top of the detail. Before the analysis there is no name yet, so it says what is
/// going on with the video.
String entryTitle(Entry entry) => switch (entry.content) {
  RecipeContent(:final title) => title,
  RestaurantContent(:final name) => name,
  null => switch (entry.status) {
    Analyzing() => 'Izdvajamo recept iz videa',
    AnalysisFailed(:final reason) => _failureTitle(reason),
    _ => 'Video sa ${_sourceName(entry.source)}',
  },
};

String _failureTitle(AnalysisFailure reason) => switch (reason) {
  AnalysisFailure.unavailable => 'Video nije dostupan',
  AnalysisFailure.notFood => 'Nismo prepoznali hranu',
  AnalysisFailure.timeout => 'Analiza je predugo trajala',
  AnalysisFailure.unsupported => 'Video nije podržan',
};

String _sourceName(EntrySource source) => switch (source) {
  FromVideo(:final link) => switch (link.platform) {
    VideoPlatform.instagram => 'Instagrama',
    VideoPlatform.tiktok => 'TikToka',
  },
  Manual() => 'telefona',
};

/// The short facts under the name: time and servings for a recipe, place, cuisine and price for a restaurant.
List<EntryFact> factsOf(EntryContent? content) => switch (content) {
  RecipeContent(:final prepTime, :final servings) => [
    if (prepTime != null) EntryFact(icon: AppIcons.time, text: '${prepTime.inMinutes} min'),
    EntryFact(icon: AppIcons.group, text: servingsText(servings)),
  ],
  RestaurantContent(:final location, :final cuisine, :final priceRange) => [
    EntryFact(icon: AppIcons.location, text: location.city),
    EntryFact(icon: AppIcons.cuisine, text: cuisine),
    if (priceRange != null) EntryFact(icon: AppIcons.price, text: priceText(priceRange)),
  ],
  null => const [],
};

/// The frame of the video: a demo photo in KT1, an address from the server from KT2.
ImageProvider? photoOf(Entry entry) => switch (entry.source) {
  FromVideo(:final thumbnail?) => AssetImage('assets/demo/$thumbnail.jpg'),
  _ => null,
};

/// The picture when there is no frame.
AppIllustrations illustrationOf(EntryContent? content) => switch (content) {
  RecipeContent() => AppIllustrations.mainCourse,
  RestaurantContent() => AppIllustrations.restaurant,
  null => AppIllustrations.video,
};

/// The owner's own words, in mustard next to what the AI extracted.
String? personalSummary(PersonalLayer personal) {
  if (personal.note.isNotEmpty) return personal.note;
  return switch (personal.wouldReturn) {
    WouldReturn.yes => 'Vratio bih se',
    WouldReturn.maybe => 'Možda bih se vratio',
    WouldReturn.no => 'Ne bih se vratio',
    null => null,
  };
}
