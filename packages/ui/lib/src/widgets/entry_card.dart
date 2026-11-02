import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_space.dart';
import '../theme/app_text.dart';
import '../theme/entry_kind_colors.dart';
import 'app_icon.dart';
import 'card_frame.dart';
import 'entry_fact.dart';
import 'personal_note.dart';
import 'status_badge.dart';
import 'type_label.dart';

/// One entry in a list (M-03): thumbnail on the left, type and status on top, title, facts, the personal note
/// and at the bottom the author with "1 od 3", or [actions].
///
/// [details] is free space under the title for a state that needs more than facts: the analysis step with a
/// progress bar, or the reason an analysis failed.
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.kind,
    required this.status,
    required this.title,
    required this.thumb,
    this.facts = const [],
    this.personalNote,
    this.details,
    this.author,
    this.groupLabel,
    this.actions,
    this.onTap,
  });

  final EntryCardKind kind;
  final BadgeStatus status;
  final String title;

  /// Usually a `ReelThumb`.
  final Widget thumb;
  final List<EntryFact> facts;
  final String? personalNote;
  final Widget? details;

  /// "@doruckuj.brzo", "Tvoj recept" or a short hint such as "Javićemo ti kad završimo".
  final String? author;

  /// "1 od 3" when one video produced several entries.
  final String? groupLabel;

  /// Replaces the author line, for example "Pokušaj ponovo" and "Unesi ručno".
  final Widget? actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = CardFrame(
      rimColor: theme.kindColors.rimFor(kind),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.insideCard),
        // The text column is as tall as the thumbnail at least, so the footer sits at the bottom.
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              thumb,
              const SizedBox(width: AppSpace.thumbText),
              Expanded(child: _body(theme)),
            ],
          ),
        ),
      ),
    );
    // A screen reader reads a card as one item, unless it has buttons that must stay separate.
    return actions == null ? MergeSemantics(child: card) : card;
  }

  Widget _body(ThemeData theme) {
    final footer = _footer(theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: TypeLabel(kind)),
            const SizedBox(width: 8),
            StatusBadge(status),
          ],
        ),
        const SizedBox(height: 8),
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 7),
        if (facts.isNotEmpty) Wrap(spacing: 12, runSpacing: 5, children: facts),
        if (personalNote case final note?) ...[const SizedBox(height: 9), PersonalNote(note)],
        ?details,
        const Spacer(),
        if (footer != null) ...[const SizedBox(height: 10), footer],
      ],
    );
  }

  Widget? _footer(ThemeData theme) {
    if (actions case final actions?) return actions;
    if (author == null && groupLabel == null) return null;
    return Row(
      children: [
        Expanded(
          child: Text(
            author ?? '',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (groupLabel case final group?) ...[
          const SizedBox(width: 8),
          const AppIcon(AppIcons.group, size: 15),
          const SizedBox(width: 5),
          Text(group, style: AppText.label.copyWith(color: theme.colorScheme.onSurface)),
        ],
      ],
    );
  }
}
