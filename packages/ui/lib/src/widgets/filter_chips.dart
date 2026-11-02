import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_text.dart';
import '../theme/status_colors.dart';

/// One chip in `FilterChips`.
class FilterChipItem {
  const FilterChipItem({required this.label, this.count, this.highlighted = false});

  final String label;

  /// Small number after the label, e.g. how many entries wait for review.
  final int? count;

  /// Mustard chip for something the user still owes ("Za pregled").
  final bool highlighted;
}

/// Row of status filters that scrolls sideways (M-03: Za pregled · U obradi · Sačuvano · U katalogu · Odbijeno).
class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.items,
    required this.onSelected,
    this.selectedIndex,
    this.padding = EdgeInsets.zero,
  });

  final List<FilterChipItem> items;
  final ValueChanged<int> onSelected;

  /// No chip is selected when null.
  final int? selectedIndex;

  /// Lets the chips scroll to the screen edge while the first one lines up with the content.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _Chip(item: items[i], selected: i == selectedIndex, onTap: () => onSelected(i)),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.item, required this.selected, required this.onTap});

  final FilterChipItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final review = theme.statusColors.awaitingReview;
    // A selected chip is ink with white text, like the "U katalogu" badge.
    final (background, border, foreground) = selected
        ? (scheme.primary, scheme.primary, scheme.onPrimary)
        : item.highlighted
        ? (review.background, theme.statusColors.reviewBorder, review.foreground)
        : (scheme.surface, scheme.outline, scheme.onSurfaceVariant);

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        // The chip is 32 px high, but the area you can tap is 44 px.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: background,
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.label, style: AppText.chip.copyWith(color: foreground)),
                  if (item.count case final count?) ...[
                    const SizedBox(width: 6),
                    _Count(count: count, highlighted: item.highlighted),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.count, required this.highlighted});

  final int count;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: highlighted ? scheme.secondary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        '$count',
        style: theme.textTheme.labelSmall?.copyWith(color: highlighted ? scheme.onSecondary : scheme.onSurfaceVariant),
      ),
    );
  }
}
