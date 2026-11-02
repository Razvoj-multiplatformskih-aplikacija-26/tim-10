import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_icons.dart';
import '../theme/app_text.dart';

/// One of our SVG icons, painted in a single color. We never use Material `Icons.*`.
///
/// Without a [color] it takes the main text color of the theme.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = 24, this.color});

  final AppIcons icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      icon.path,
      package: AppText.package,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
