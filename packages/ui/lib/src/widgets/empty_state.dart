import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import 'app_illustration.dart';

/// Empty list: illustration, title, one sentence and the actions that get the user started.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.illustration = AppIllustrations.emptyLibrary,
    this.actions = const [],
    this.footer,
  });

  final String title;
  final String message;
  final AppIllustrations illustration;

  /// Usually a `PrimaryButton` and a `GhostButton`.
  final List<Widget> actions;

  /// Extra content under the buttons, such as the three steps for sharing from Instagram.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIllustration(illustration),
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
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: actions),
        ],
        if (footer case final footer?) ...[const SizedBox(height: 22), footer],
      ],
    );
  }
}
