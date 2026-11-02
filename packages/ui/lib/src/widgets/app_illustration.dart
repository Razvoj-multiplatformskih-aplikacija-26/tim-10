import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_icons.dart';
import '../theme/app_text.dart';

/// One of our SVG illustrations in its own colors. Without a size it keeps the size it was drawn at.
class AppIllustration extends StatelessWidget {
  const AppIllustration(this.illustration, {super.key, this.width, this.height, this.fit = BoxFit.contain});

  final AppIllustrations illustration;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      illustration.path,
      package: AppText.package,
      width: width,
      height: height,
      fit: fit,
      excludeFromSemantics: true,
    );
  }
}
