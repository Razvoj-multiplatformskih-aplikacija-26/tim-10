import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'entry_text.dart';

/// One entry on the library's list: the shared card, filled in from the domain.
class EntryTile extends StatelessWidget {
  const EntryTile({super.key, required this.entry, this.actions, this.onTap});

  final Entry entry;
  final Widget? actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final source = entry.source;
    return EntryCard(
      kind: cardKindOf(entry.content),
      status: badgeStatusOf(entry.status),
      title: entryTitle(entry),
      thumb: ReelThumb(
        photo: photoOf(entry),
        illustration: photoOf(entry) == null ? illustrationOf(entry.content) : null,
        sourceLabel: switch (source) {
          FromVideo(:final link) => platformText(link.platform),
          Manual() => 'Ručno',
        },
        stacked: source is FromVideo && source.itemCount > 1,
        dimmed: entry.status.isBeingAnalyzed,
      ),
      facts: factsOf(entry.content),
      personalNote: personalSummary(entry.personal),
      details: _details(context),
      author: switch (entry.status) {
        Analyzing() => 'Javićemo ti kad završimo',
        _ => switch (source) {
          FromVideo(:final author) => author,
          Manual() => 'Tvoj unos',
        },
      },
      groupLabel: source is FromVideo && source.itemCount > 1 ? '${source.itemIndex + 1} od ${source.itemCount}' : null,
      actions: actions,
      onTap: onTap,
    );
  }

  Widget? _details(BuildContext context) {
    final theme = Theme.of(context);
    return switch (entry.status) {
      Queued() => Text(
        'Na redu je za analizu',
        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      Analyzing() => const LinearProgressIndicator(value: 0.5, minHeight: 6),
      AnalysisFailed(:final reason) => Text(
        analysisFailureText(reason),
        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
      ),
      Rejected(:final reason) => Text(
        'Urednik: ${reason.text}',
        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
      ),
      AwaitingReview() || Saved() || PendingApproval() || Published() => null,
    };
  }
}
