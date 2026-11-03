import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'queue_rows.dart';
import 'review_text.dart';

/// The narrow layout of the queue: the same proposals, a list instead of a table.
class QueueList extends StatelessWidget {
  const QueueList({super.key, required this.state, required this.now, required this.focusNode, required this.onOpen});

  static const rowHeight = 76.0;

  final ReviewQueueLoaded state;
  final DateTime now;
  final FocusNode focusNode;
  final ValueChanged<EntryId> onOpen;

  @override
  Widget build(BuildContext context) {
    return QueueRows(
      count: state.items.length,
      cursor: state.cursor,
      rowHeight: rowHeight,
      focusNode: focusNode,
      rowBuilder: (context, index, hasFocus) {
        final item = state.items[index];
        final isCursor = index == state.cursor;
        return QueueRowFrame(
          key: ValueKey(item.id.value),
          isCursor: isCursor,
          isOpen: isCursor && state.isPanelOpen,
          hasFocus: hasFocus,
          child: _Row(item: item, now: now, onTap: () => onOpen(item.id)),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.now, required this.onTap});

  final ReviewItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      canRequestFocus: false,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titleOf(item.content), style: AppText.cardTitle, overflow: TextOverflow.ellipsis),
                  Text(
                    '${summaryOf(item.content)}, ${item.proposedBy.value}, ${agoText(item.submittedAt, now: now)}',
                    style: AppText.body.copyWith(color: secondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (item.duplicates.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text('${item.duplicates.length} dupl.', style: AppText.label.copyWith(color: AppColors.tomato)),
            ],
          ],
        ),
      ),
    );
  }
}
