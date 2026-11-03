import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
import 'package:ui/ui.dart';

import 'entry_text.dart';

/// "Obriši" cannot be undone, so it asks first (KT1).
Future<bool> confirmDelete(BuildContext context, Entry entry) => _confirm(
  context,
  title: switch (entry.content) {
    RecipeContent() => 'Obrisati recept?',
    RestaurantContent() => 'Obrisati restoran?',
    null => 'Obrisati unos?',
  },
  message: 'Tvoje beleške i fotografije biće obrisane.',
  action: 'Obriši',
);

/// M-19: what goes public and what stays private, before the entry goes to the editor.
Future<bool> confirmPropose(BuildContext context, Entry entry) => _confirm(
  context,
  title: 'Predložiti za katalog?',
  message:
      'Predloži ${entryTitle(entry)} za javni katalog? Objavljuju se samo podaci iz videa. '
      'Tvoje beleške, potrošnja i fotografije ostaju privatne.',
  action: 'Predloži',
);

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        GhostButton(label: 'Odustani', size: ButtonSize.md, onPressed: () => Navigator.of(context).pop(false)),
        PrimaryButton(label: action, size: ButtonSize.md, onPressed: () => Navigator.of(context).pop(true)),
      ],
    ),
  );
  return confirmed ?? false;
}
