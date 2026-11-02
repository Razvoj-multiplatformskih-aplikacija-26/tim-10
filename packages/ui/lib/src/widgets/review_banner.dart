import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/status_colors.dart';
import 'button_size.dart';
import 'primary_button.dart';

/// Mustard banner at the top of the library: "2 videa čekaju pregled" with two tilted thumbnails and a button.
///
/// The caller passes the finished text, so the plural ("1 video čeka", "2 videa čekaju") is chosen in one place.
class ReviewBanner extends StatelessWidget {
  const ReviewBanner({
    super.key,
    required this.title,
    required this.message,
    required this.photos,
    required this.onPressed,
    this.actionLabel = 'Pregledaj',
  });

  final String title;
  final String message;

  /// Up to two photos of the entries waiting for review.
  final List<ImageProvider> photos;
  final VoidCallback onPressed;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final review = theme.statusColors.awaitingReview;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: review.background,
        border: Border.all(color: theme.statusColors.reviewBorder),
        borderRadius: BorderRadius.circular(AppRadius.banner),
      ),
      child: Row(
        children: [
          if (photos.isNotEmpty) ...[ExcludeSemantics(child: _MiniThumbs(photos: photos)), const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.25)),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                    color: review.foreground,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PrimaryButton(label: actionLabel, onPressed: onPressed, size: ButtonSize.md),
        ],
      ),
    );
  }
}

/// Two small thumbnails, tilted and overlapping.
class _MiniThumbs extends StatelessWidget {
  const _MiniThumbs({required this.photos});

  final List<ImageProvider> photos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 58,
      child: Stack(
        children: [
          if (photos.length > 1) Positioned(left: 14, top: 0, child: _MiniThumb(photo: photos[0], degrees: 6)),
          Positioned(left: 0, top: 5, child: _MiniThumb(photo: photos.last, degrees: -5)),
        ],
      ),
    );
  }
}

class _MiniThumb extends StatelessWidget {
  const _MiniThumb({required this.photo, required this.degrees});

  final ImageProvider photo;
  final double degrees;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Transform.rotate(
      angle: degrees * math.pi / 180,
      child: Container(
        width: 30,
        height: 53,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: scheme.surface, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.35),
              offset: const Offset(0, 2),
              blurRadius: 6,
              spreadRadius: -2,
            ),
          ],
          image: DecorationImage(image: photo, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
