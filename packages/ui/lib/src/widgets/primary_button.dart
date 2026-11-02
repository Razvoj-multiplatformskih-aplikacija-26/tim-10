import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_icon.dart';
import 'button_size.dart';

/// Dark `primary` (ink) button for the main action on a screen.
///
/// Disabled when [onPressed] is null. While [isBusy] it is disabled too, but stays dark and shows a spinner.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = ButtonSize.lg,
    this.icon,
    this.isBusy = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonSize size;
  final AppIcons? icon;
  final bool isBusy;

  /// Takes the full width, like "Analiziraj video" at the bottom of a form.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = onPressed != null && !isBusy;
    final foreground = enabled || isBusy ? scheme.onPrimary : scheme.onSurfaceVariant;
    return FilledButton(
      onPressed: isBusy ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(expanded ? double.infinity : 0, size.height),
        padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
        textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: size.fontSize),
        disabledBackgroundColor: isBusy ? scheme.onSurfaceVariant : scheme.surfaceContainerHighest,
        disabledForegroundColor: foreground,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBusy)
            SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: scheme.onPrimary))
          else if (icon case final icon?)
            AppIcon(icon, size: 18, color: foreground),
          if (isBusy || icon != null) const SizedBox(width: 8),
          Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
