import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('the showcase opens with the library title and the bottom navigation', (tester) async {
    await tester.pumpWidget(const MobileApp());

    expect(find.text('Biblioteka'), findsWidgets);
    expect(find.text('Proteinske palačinke sa bananom'), findsOneWidget);
    expect(find.text('Dodaj'), findsOneWidget);
  });
}
