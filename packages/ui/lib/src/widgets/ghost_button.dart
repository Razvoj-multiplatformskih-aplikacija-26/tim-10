import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_icon.dart';
import 'button_size.dart';

/// Outlined button for the second action next to a `PrimaryButton` ("Pogledaj primer", "Pokušaj ponovo").
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = ButtonSize.lg,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final AppIcons? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onPressed != null;
    final color = enabled ? scheme.onSurface : scheme.onSurfaceVariant;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(expanded ? double.infinity : 0, size.height),
        padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
        textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: size.fontSize),
        disabledForegroundColor: scheme.onSurfaceVariant,
        side: BorderSide(color: enabled ? scheme.onSurface : scheme.outline, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final icon?) ...[AppIcon(icon, size: 18, color: color), const SizedBox(width: 8)],
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
