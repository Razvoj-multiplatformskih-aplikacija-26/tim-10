import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import '../theme/entry_kind_colors.dart';
import 'app_icon.dart';

/// "Recept", "Restoran" or "Video" with its icon, top left on a card.
class TypeLabel extends StatelessWidget {
  const TypeLabel(this.kind, {super.key});

  final EntryCardKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, text, color) = switch (kind) {
      EntryCardKind.recipe => (AppIcons.recipe, 'Recept', theme.kindColors.recipe),
      EntryCardKind.restaurant => (AppIcons.restaurant, 'Restoran', theme.kindColors.restaurant),
      // The neutral rim color is too light for text, so the label uses the secondary text color.
      EntryCardKind.unknown => (AppIcons.video, 'Video', theme.colorScheme.onSurfaceVariant),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(text, style: AppText.label.copyWith(color: color)),
      ],
    );
  }
}
