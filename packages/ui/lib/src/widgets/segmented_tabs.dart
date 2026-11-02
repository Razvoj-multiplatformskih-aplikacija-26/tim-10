import 'package:flutter/material.dart';

import '../theme/app_radius.dart';

/// Segment control in a gray track (M-03: Sve / Recepti / Restorani / Kolekcije).
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.selectedIndex, required this.onSelected});

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: _Segment(label: labels[i], selected: i == selectedIndex, onTap: () => onSelected(i)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: selected
              ? BoxDecoration(
                  color: scheme.surface,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(color: scheme.shadow.withValues(alpha: 0.14), offset: const Offset(0, 1), blurRadius: 2),
                  ],
                )
              : null,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 36),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
