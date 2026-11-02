import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Background and text color of one status badge.
@immutable
class BadgeColors {
  const BadgeColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  static BadgeColors lerp(BadgeColors a, BadgeColors b, double t) => BadgeColors(
    background: Color.lerp(a.background, b.background, t)!,
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
  );
}

/// Colors of the eight entry states, as a theme extension (like `status_colors.dart` in Rafstoran).
///
/// Widgets read them with `Theme.of(context).statusColors`, so a dark theme only needs a second instance.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.queued,
    required this.analyzing,
    required this.awaitingReview,
    required this.saved,
    required this.analysisFailed,
    required this.pendingApproval,
    required this.published,
    required this.rejected,
    required this.reviewBorder,
  });

  static const light = StatusColors(
    queued: BadgeColors(background: AppColors.track, foreground: AppColors.ink2),
    analyzing: BadgeColors(background: AppColors.cobaltSoft, foreground: AppColors.cobalt),
    awaitingReview: BadgeColors(background: AppColors.mustardSoft, foreground: AppColors.mustardInk),
    saved: BadgeColors(background: AppColors.peaSoft, foreground: AppColors.pea),
    analysisFailed: BadgeColors(background: AppColors.tomatoSoft, foreground: AppColors.maroon),
    pendingApproval: BadgeColors(background: AppColors.plumSoft, foreground: AppColors.plum),
    published: BadgeColors(background: AppColors.ink, foreground: AppColors.onInk),
    rejected: BadgeColors(background: AppColors.track, foreground: AppColors.maroon),
    reviewBorder: AppColors.mustardLine,
  );

  final BadgeColors queued;
  final BadgeColors analyzing;
  final BadgeColors awaitingReview;
  final BadgeColors saved;
  final BadgeColors analysisFailed;
  final BadgeColors pendingApproval;
  final BadgeColors published;
  final BadgeColors rejected;

  /// Border of the surfaces that ask for a review: the "Za pregled" chip and the review banner.
  final Color reviewBorder;

  @override
  StatusColors copyWith({
    BadgeColors? queued,
    BadgeColors? analyzing,
    BadgeColors? awaitingReview,
    BadgeColors? saved,
    BadgeColors? analysisFailed,
    BadgeColors? pendingApproval,
    BadgeColors? published,
    BadgeColors? rejected,
    Color? reviewBorder,
  }) {
    return StatusColors(
      queued: queued ?? this.queued,
      analyzing: analyzing ?? this.analyzing,
      awaitingReview: awaitingReview ?? this.awaitingReview,
      saved: saved ?? this.saved,
      analysisFailed: analysisFailed ?? this.analysisFailed,
      pendingApproval: pendingApproval ?? this.pendingApproval,
      published: published ?? this.published,
      rejected: rejected ?? this.rejected,
      reviewBorder: reviewBorder ?? this.reviewBorder,
    );
  }

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      queued: BadgeColors.lerp(queued, other.queued, t),
      analyzing: BadgeColors.lerp(analyzing, other.analyzing, t),
      awaitingReview: BadgeColors.lerp(awaitingReview, other.awaitingReview, t),
      saved: BadgeColors.lerp(saved, other.saved, t),
      analysisFailed: BadgeColors.lerp(analysisFailed, other.analysisFailed, t),
      pendingApproval: BadgeColors.lerp(pendingApproval, other.pendingApproval, t),
      published: BadgeColors.lerp(published, other.published, t),
      rejected: BadgeColors.lerp(rejected, other.rejected, t),
      reviewBorder: Color.lerp(reviewBorder, other.reviewBorder, t)!,
    );
  }
}

extension StatusColorsX on ThemeData {
  StatusColors get statusColors => extension<StatusColors>() ?? StatusColors.light;
}
