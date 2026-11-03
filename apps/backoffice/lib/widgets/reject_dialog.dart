import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

/// Asks for the reason of a rejection. Returns it, or `null` when the editor changed their mind.
///
/// The rule is in the domain (`RejectionReason.parse`, R8); the dialog only shows its answer.
Future<RejectionReason?> showRejectDialog(BuildContext context, {required DateTime now}) => showDialog<RejectionReason>(
  context: context,
  builder: (_) => _RejectDialog(now: now),
);

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.now});

  final DateTime now;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _reason = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit() {
    switch (RejectionReason.parse(_reason.text)) {
      case Success(:final value):
        Navigator.of(context).pop(value);
      case Failure(:final error):
        setState(() => _error = domainErrorText(error, now: widget.now));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Odbij predlog'),
      content: SizedBox(
        width: 420,
        child: TextField(
          key: const Key('reject-reason'),
          controller: _reason,
          autofocus: true,
          maxLength: RejectionReason.maxLength,
          decoration: InputDecoration(labelText: 'Razlog (vidi ga korisnik)', errorText: _error),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        GhostButton(label: 'Odustani', size: ButtonSize.md, onPressed: () => Navigator.of(context).pop()),
        PrimaryButton(label: 'Odbij', size: ButtonSize.md, onPressed: _submit),
      ],
    );
  }
}
