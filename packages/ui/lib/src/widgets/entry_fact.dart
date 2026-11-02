import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_icon.dart';

/// One short fact on a card with its icon: "15 min", "310 kcal po porciji", "Dorćol", "€€".
class EntryFact extends StatelessWidget {
  const EntryFact({super.key, required this.icon, required this.text});

  final AppIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(text, style: theme.textTheme.labelMedium?.copyWith(color: color)),
      ],
    );
  }
}
