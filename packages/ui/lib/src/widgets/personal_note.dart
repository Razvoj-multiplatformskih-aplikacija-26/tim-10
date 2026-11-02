import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import 'app_icon.dart';

/// The user's own note on a card, in mustard (`secondary`) so it stays apart from what the AI extracted.
class PersonalNote extends StatelessWidget {
  const PersonalNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
      decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.personal, size: 14, color: scheme.onSecondaryContainer),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              style: AppText.label.copyWith(fontWeight: FontWeight.w600, color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
