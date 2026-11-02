import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/app_text.dart';

/// Upright 9:16 thumbnail, like a reel.
///
/// Shows a [photo] (a frame from the video or the user's photo), otherwise an [illustration] of the category,
/// otherwise an empty gray box. [stacked] draws two frames behind it for a video with several entries.
class ReelThumb extends StatelessWidget {
  const ReelThumb({
    super.key,
    this.photo,
    this.illustration,
    this.sourceLabel,
    this.stacked = false,
    this.dimmed = false,
  });

  static const double width = 74;
  static const double height = 131;

  final ImageProvider? photo;
  final AppIllustrations? illustration;

  /// "Instagram", "TikTok" or "Ručno".
  final String? sourceLabel;
  final bool stacked;

  /// Darkens the frame while the video is being analyzed.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.thumb);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (stacked) ...[
            _StackedFrame(offset: const Offset(8, -8), radius: radius),
            _StackedFrame(offset: const Offset(4, -4), radius: radius),
          ],
          Positioned.fill(
            child: ClipRRect(borderRadius: radius, child: _cover(scheme)),
          ),
          if (dimmed)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: scheme.scrim.withValues(alpha: 0.38), borderRadius: radius),
              ),
            ),
          if (sourceLabel case final label?)
            Positioned(
              left: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.inverseSurface.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(label, style: AppText.sourceLabel.copyWith(color: scheme.onInverseSurface)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cover(ColorScheme scheme) {
    if (photo case final photo?) {
      return Image(image: photo, fit: BoxFit.cover, excludeFromSemantics: true);
    }
    if (illustration case final illustration?) {
      return SvgPicture.asset(
        illustration.path,
        package: AppText.package,
        fit: BoxFit.cover,
        excludeFromSemantics: true,
      );
    }
    return ColoredBox(color: scheme.surfaceContainerHighest);
  }
}

class _StackedFrame extends StatelessWidget {
  const _StackedFrame({required this.offset, required this.radius});

  final Offset offset;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: Transform.translate(
        offset: offset,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: radius,
            border: Border.all(color: scheme.outline, width: 1.5),
          ),
        ),
      ),
    );
  }
}
