import 'package:blocs/blocs.dart';
import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'review_text.dart';

/// The wide layout of the queue: one proposal per row.
class QueueTable extends StatelessWidget {
  const QueueTable({super.key, required this.state, required this.now, required this.onOpen});

  static const rowHeight = 56.0;

  final ReviewQueueLoaded state;
  final DateTime now;
  final ValueChanged<EntryId> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _HeaderRow(),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemExtent: rowHeight,
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _Row(key: ValueKey(item.id.value), item: item, now: now, onTap: () => onOpen(item.id));
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = AppText.label.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: _kindWidth,
            child: Text('Tip', style: style),
          ),
          Expanded(flex: 3, child: Text('Naziv', style: style)),
          Expanded(flex: 2, child: Text('Grad, kuhinja ili vreme', style: style)),
          SizedBox(
            width: _ownerWidth,
            child: Text('Predložio', style: style),
          ),
          SizedBox(
            width: _timeWidth,
            child: Text('Kada', style: style),
          ),
          SizedBox(
            width: _duplicatesWidth,
            child: Text('Duplikati', style: style),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({super.key, required this.item, required this.now, required this.onTap});

  final ReviewItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        child: Row(
          children: [
            SizedBox(
              width: _kindWidth,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: TypeLabel(kindOf(item.content)),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(titleOf(item.content), style: AppText.cardTitle, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              flex: 2,
              child: Text(summaryOf(item.content), style: AppText.body, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(
              width: _ownerWidth,
              child: Text(item.proposedBy.value, style: AppText.body, overflow: TextOverflow.ellipsis),
            ),
            SizedBox(
              width: _timeWidth,
              child: Text(agoText(item.submittedAt, now: now), style: AppText.body),
            ),
            SizedBox(
              width: _duplicatesWidth,
              child: item.duplicates.isEmpty
                  ? const Text('—', style: AppText.body)
                  : Text('${item.duplicates.length}', style: AppText.cardTitle.copyWith(color: AppColors.tomato)),
            ),
          ],
        ),
      ),
    );
  }
}

const _kindWidth = 110.0;
const _ownerWidth = 100.0;
const _timeWidth = 90.0;
const _duplicatesWidth = 70.0;
