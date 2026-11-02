import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import 'app_icon.dart';

/// Bottom navigation of the mobile app: Biblioteka · Mapa · + Dodaj · Lista · Profil.
///
/// "Dodaj" is not a tab, it opens the form over the whole screen, so it has its own [onAdd].
class AppTabBar extends StatelessWidget {
  const AppTabBar({super.key, required this.currentIndex, required this.onSelected, required this.onAdd});

  /// Open tab: 0 Biblioteka, 1 Mapa, 2 Lista, 3 Profil.
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Tab(
                icon: AppIcons.library,
                label: 'Biblioteka',
                selected: currentIndex == 0,
                onTap: () => onSelected(0),
              ),
              _Tab(icon: AppIcons.map, label: 'Mapa', selected: currentIndex == 1, onTap: () => onSelected(1)),
              _AddTab(onTap: onAdd),
              _Tab(
                icon: AppIcons.shoppingList,
                label: 'Lista',
                selected: currentIndex == 2,
                onTap: () => onSelected(2),
              ),
              _Tab(icon: AppIcons.profile, label: 'Profil', selected: currentIndex == 3, onTap: () => onSelected(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.selected, required this.onTap});

  final AppIcons icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(icon, color: color),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: AppText.tab.copyWith(color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The raised dark "+" in the middle; it sticks 16 px above the bar.
///
/// The whole item (the "+" and the label) is one tap target of at least 48 px, like the other tabs.
class _AddTab extends StatelessWidget {
  const _AddTab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 30,
                  child: OverflowBox(
                    alignment: Alignment.bottomCenter,
                    maxHeight: 46,
                    child: Container(
                      width: 52,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.7),
                            offset: const Offset(0, 8),
                            blurRadius: 16,
                            spreadRadius: -8,
                          ),
                        ],
                      ),
                      child: AppIcon(AppIcons.add, size: 26, color: scheme.onPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text('Dodaj', style: AppText.tab.copyWith(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
