import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_illustration.dart';
import 'primary_button.dart';

/// Loading failed: cracked plate, what happened, "Pokušaj ponovo" and an optional hint below.
///
/// [onRetry] sends the same event as the first load.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.retryLabel = 'Pokušaj ponovo',
    this.hint,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  /// "Ako se ponavlja, proveri internet vezu."
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryText = theme.colorScheme.onSurfaceVariant;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppIllustration(AppIllustrations.error),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: secondaryText),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: retryLabel, onPressed: onRetry),
        if (hint case final hint?) ...[
          const SizedBox(height: 14),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w400, color: secondaryText),
          ),
        ],
      ],
    );
  }
}
