/// The four button heights from the drafts: 54 sticky form button, 50 state screens, 44 rows, 36 inside a card.
enum ButtonSize {
  xl(height: 54, fontSize: 16, horizontalPadding: 20),
  lg(height: 50, fontSize: 15, horizontalPadding: 20),
  md(height: 44, fontSize: 14, horizontalPadding: 14),
  sm(height: 36, fontSize: 13, horizontalPadding: 12);

  const ButtonSize({required this.height, required this.fontSize, required this.horizontalPadding});

  final double height;
  final double fontSize;
  final double horizontalPadding;
}
