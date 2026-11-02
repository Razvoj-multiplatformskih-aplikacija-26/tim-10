import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// White rounded card with a thin colored rim along the top edge (the type of the entry).
///
/// Shared by `EntryCard` and `EntryCardSkeleton`, so both have exactly the same shape.
class CardFrame extends StatelessWidget {
  const CardFrame({super.key, required this.rimColor, required this.child, this.onTap});

  static const double rimWidth = 3;

  final Color rimColor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.card);
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: radius,
          border: Border.all(color: scheme.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: CustomPaint(painter: _TopRimPainter(rimColor), child: child),
        ),
      ),
    );
  }
}

/// Paints the card shape minus the same shape moved [CardFrame.rimWidth] down: a band that is 3 px thick
/// in the middle and thins out along the rounded corners.
class _TopRimPainter extends CustomPainter {
  const _TopRimPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.card));
    final rim = Path.combine(
      PathOperation.difference,
      Path()..addRRect(card),
      Path()..addRRect(card.shift(const Offset(0, CardFrame.rimWidth))),
    );
    canvas.drawPath(rim, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TopRimPainter oldDelegate) => oldDelegate.color != color;
}
