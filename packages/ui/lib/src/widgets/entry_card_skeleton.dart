import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_space.dart';
import 'card_frame.dart';
import 'reel_thumb.dart';

/// Gray outline of an `EntryCard` while the list is loading.
class EntryCardSkeleton extends StatelessWidget {
  const EntryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CardFrame(
        rimColor: Theme.of(context).colorScheme.outline,
        child: const Padding(
          padding: EdgeInsets.all(AppSpace.insideCard),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Bar(width: ReelThumb.width, height: ReelThumb.height, radius: AppRadius.thumb),
              SizedBox(width: AppSpace.thumbText),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _Bar(width: 70, height: 14),
                        _Bar(width: 84, height: 22, radius: AppRadius.pill),
                      ],
                    ),
                    SizedBox(height: 14),
                    _Line(percent: 92, height: 18),
                    SizedBox(height: 8),
                    _Line(percent: 58, height: 18),
                    SizedBox(height: 14),
                    _Line(percent: 66, height: 13),
                    SizedBox(height: 22),
                    _Line(percent: 40, height: 13),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({this.width, required this.height, this.radius = 7});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A bar that takes [percent] of the available width.
class _Line extends StatelessWidget {
  const _Line({required this.percent, required this.height});

  final int percent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: percent,
          child: _Bar(height: height),
        ),
        Spacer(flex: 100 - percent),
      ],
    );
  }
}
