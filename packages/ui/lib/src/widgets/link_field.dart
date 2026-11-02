import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_radius.dart';
import '../theme/status_colors.dart';
import 'app_icon.dart';

/// Field for a video link (M-05): label above, link icon, "×" to clear, green frame when the link is valid and
/// a red frame with the reason when it is not.
///
/// The field does not check the link. The screen calls the domain `parse` and passes [errorText] or [isValid].
class LinkField extends StatelessWidget {
  const LinkField({
    super.key,
    required this.controller,
    this.label = 'Link do videa',
    this.hint = 'https://…',
    this.errorText,
    this.isValid = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? errorText;
  final bool isValid;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A valid link gets the same green as the "Sačuvano" badge.
    final OutlineInputBorder? stateBorder = switch ((errorText, isValid)) {
      (String(), _) => _border(scheme.error),
      (null, true) => _border(theme.statusColors.saved.foreground),
      (null, false) => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        Opacity(
          opacity: enabled ? 1 : 0.55,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            autofocus: autofocus,
            onChanged: onChanged,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            // 16 px, so iOS does not zoom into the field.
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(vertical: 17),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: AppIcon(AppIcons.link, size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minHeight: 20),
              suffixIcon: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => controller.text.isEmpty || !enabled
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Obriši',
                        onPressed: _clear,
                        icon: AppIcon(AppIcons.close, size: 18, color: scheme.onSurfaceVariant),
                      ),
              ),
              enabledBorder: stateBorder,
              focusedBorder: stateBorder,
            ),
          ),
        ),
        if (errorText case final error?) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: AppIcon(AppIcons.analysisFailed, size: 16, color: scheme.onErrorContainer),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontSize: 13.5,
                    height: 1.4,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _clear() {
    controller.clear();
    onChanged?.call('');
  }

  static OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.field),
    borderSide: BorderSide(color: color, width: 2),
  );
}
