import 'package:flutter/material.dart';

/// The scrolling rows under the table and the list: keeps the row under the cursor in view.
///
/// A row has a fixed height, so its position is a simple multiplication.
class QueueRows extends StatefulWidget {
  const QueueRows({
    super.key,
    required this.count,
    required this.cursor,
    required this.rowHeight,
    required this.focusNode,
    required this.rowBuilder,
  });

  final int count;
  final int cursor;
  final double rowHeight;

  /// The screen's focus node: while it has the focus, the row under the cursor shows a frame (visible focus).
  final FocusNode focusNode;

  final Widget Function(BuildContext context, int index, bool hasFocus) rowBuilder;

  @override
  State<QueueRows> createState() => _QueueRowsState();
}

class _QueueRowsState extends State<QueueRows> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // A narrower window builds a new list; it opens where the cursor is, not at the top.
    WidgetsBinding.instance.addPostFrameCallback((_) => _keepCursorInView(animate: false));
  }

  @override
  void didUpdateWidget(QueueRows oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cursor != widget.cursor) _keepCursorInView(animate: true);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _keepCursorInView({required bool animate}) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final top = widget.cursor * widget.rowHeight;
    final bottom = top + widget.rowHeight;

    final double target;
    if (top < position.pixels) {
      target = top;
    } else if (bottom > position.pixels + position.viewportDimension) {
      target = bottom - position.viewportDimension;
    } else {
      return;
    }

    if (animate) {
      _scroll.animateTo(target, duration: const Duration(milliseconds: 120), curve: Curves.easeOut);
    } else {
      _scroll.jumpTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.focusNode,
      builder: (context, _) => ListView.builder(
        controller: _scroll,
        itemExtent: widget.rowHeight,
        itemCount: widget.count,
        itemBuilder: (context, index) => widget.rowBuilder(context, index, widget.focusNode.hasFocus),
      ),
    );
  }
}

/// The look of a row, the same in the table and the list: tinted when open, framed when under a focused cursor.
BoxDecoration queueRowDecoration(
  BuildContext context, {
  required bool isCursor,
  required bool isOpen,
  required bool hasFocus,
}) {
  final colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: isOpen ? colors.surfaceContainerHighest : null,
    border: isCursor && hasFocus ? Border.all(color: colors.onSurface, width: 2) : null,
  );
}
