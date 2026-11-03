import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'review_text.dart';

/// The detail of one proposal: next to the table on a wide window, under the list on a narrow one.
///
/// It takes a [ReviewItem], which has no personal layer, so the user's notes cannot end up here (R7).
class ReviewDetailPanel extends StatelessWidget {
  const ReviewDetailPanel({
    super.key,
    required this.item,
    required this.now,
    required this.onClose,
    required this.onPublish,
    required this.onReject,
  });

  final ReviewItem item;
  final DateTime now;
  final VoidCallback onClose;

  /// `null` while a decision is running, or when the user may not decide: the button is then disabled.
  final VoidCallback? onPublish;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final details = ListView(
      key: ValueKey(item.id.value),
      padding: const EdgeInsets.all(AppSpace.screen),
      children: [
        Row(
          children: [
            TypeLabel(kindOf(item.content)),
            const Spacer(),
            IconButton(
              tooltip: 'Zatvori (Esc)',
              onPressed: onClose,
              icon: AppIcon(AppIcons.close, size: 20, color: secondary),
            ),
          ],
        ),
        Text(titleOf(item.content), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Predložio ${item.proposedBy.value}, ${agoText(item.submittedAt, now: now)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: secondary),
        ),
        Text(_sourceText(item.source), style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: secondary)),
        const SizedBox(height: 16),
        ...switch (item.content) {
          final RecipeContent recipe => _recipe(recipe),
          final RestaurantContent restaurant => _restaurant(restaurant),
        },
      ],
    );
    return Column(
      children: [
        Expanded(child: details),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpace.insideCard),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(label: 'Objavi (O)', size: ButtonSize.md, expanded: true, onPressed: onPublish),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GhostButton(label: 'Odbij (X)', size: ButtonSize.md, expanded: true, onPressed: onReject),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _recipe(RecipeContent recipe) => [
    Text(summaryOf(recipe)),
    const _Heading('Sastojci'),
    for (final ingredient in recipe.ingredients) Text('• ${_ingredientText(ingredient)}'),
    const _Heading('Koraci'),
    for (final (index, step) in recipe.steps.indexed) Text('${index + 1}. $step'),
  ];

  List<Widget> _restaurant(RestaurantContent restaurant) => [
    Text('${restaurant.location.address}, ${restaurant.location.city}'),
    Text('Kuhinja: ${restaurant.cuisine}'),
    if (restaurant.priceRange case final price?) Text('Cene: ${_priceText(price)}'),
    const _Heading('Preporučena jela'),
    for (final dish in restaurant.recommendedDishes) Text('• $dish'),
    if (restaurant.notes case final notes?) ...[const _Heading('Napomena'), Text(notes)],
    if (item.duplicates.isNotEmpty) ...[
      _Heading('Mogući duplikati u katalogu (${item.duplicates.length})'),
      for (final match in item.duplicates) _DuplicateRow(proposal: restaurant, match: match),
    ],
  ];
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

/// The proposal and the catalog record side by side, so the editor can compare them (R5).
class _DuplicateRow extends StatelessWidget {
  const _DuplicateRow({required this.proposal, required this.match});

  final RestaurantContent proposal;
  final CatalogMatch match;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: _Place(label: 'Predlog', place: proposal),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _Place(label: 'U katalogu', place: match.content),
      ),
    ],
  );
}

class _Place extends StatelessWidget {
  const _Place({required this.label, required this.place});

  final String label;
  final RestaurantContent place;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppText.label.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      Text(place.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      Text(place.location.address),
      Text(place.cuisine),
    ],
  );
}

String _sourceText(EntrySource source) => switch (source) {
  FromVideo(:final link, :final author) => 'Video: ${_platformText(link.platform)}${author == null ? '' : ', $author'}',
  Manual() => 'Uneto ručno',
};

String _platformText(VideoPlatform platform) => switch (platform) {
  VideoPlatform.instagram => 'Instagram',
  VideoPlatform.tiktok => 'TikTok',
};

String _ingredientText(Ingredient ingredient) => switch (ingredient.quantity) {
  null => ingredient.name,
  final quantity => '${ingredient.name}, ${quantity.amount} ${quantity.unit.name}',
};

String _priceText(PriceRange price) => switch (price) {
  PriceRange.budget => 'povoljne',
  PriceRange.moderate => 'umerene',
  PriceRange.expensive => 'visoke',
  PriceRange.luxury => 'luksuzne',
};
