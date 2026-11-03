import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  testWidgets('the app opens on the library, with the tabs at the bottom', (tester) async {
    usePhoneSize(tester);
    await tester.pumpWidget(appWith(fakeDependencies()));
    await tester.pumpAndSettle();

    expect(find.text('Biblioteka'), findsWidgets);
    expect(find.text('Dodaj'), findsOneWidget);
  });
}
