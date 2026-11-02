import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/status_colors.dart';
import 'app_icon.dart';

/// The eight entry states a badge can show. Names follow `EntryStatus` in `docs/sistem.md`.
///
/// Temporary: once the domain exists, `StatusBadge` takes `EntryStatus` and this enum goes away.
enum BadgeStatus { queued, analyzing, awaitingReview, saved, analysisFailed, pendingApproval, published, rejected }

/// Status of an entry, top right on a card.
class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final BadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.statusColors;
    final (badge, icon, text) = switch (status) {
      BadgeStatus.queued => (colors.queued, AppIcons.queued, 'Čeka analizu'),
      BadgeStatus.analyzing => (colors.analyzing, AppIcons.analyzing, 'Analizira se'),
      BadgeStatus.awaitingReview => (colors.awaitingReview, AppIcons.awaitingReview, 'Za pregled'),
      BadgeStatus.saved => (colors.saved, AppIcons.saved, 'Sačuvano'),
      BadgeStatus.analysisFailed => (colors.analysisFailed, AppIcons.analysisFailed, 'Nije uspelo'),
      BadgeStatus.pendingApproval => (colors.pendingApproval, AppIcons.pendingApproval, 'Čeka urednika'),
      BadgeStatus.published => (colors.published, AppIcons.published, 'U katalogu'),
      BadgeStatus.rejected => (colors.rejected, AppIcons.rejected, 'Odbijeno'),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.fromLTRB(7, 0, 9, 0),
      decoration: BoxDecoration(color: badge.background, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 14, color: badge.foreground),
          const SizedBox(width: 4),
          Text(text, style: theme.textTheme.labelSmall?.copyWith(color: badge.foreground)),
        ],
      ),
    );
  }
}
