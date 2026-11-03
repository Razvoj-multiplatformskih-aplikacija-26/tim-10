import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// The loading state: empty rows where the proposals will be.
class QueueSkeleton extends StatelessWidget {
  const QueueSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpace.screen),
      itemCount: 8,
      itemBuilder: (context, index) => Container(
        height: 40,
        margin: const EdgeInsets.only(bottom: AppSpace.betweenCards),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
      ),
    );
  }
}
