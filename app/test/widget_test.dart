import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connect4people_app/main.dart';

void main() {
  testWidgets('Connect4PeopleApp loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: Connect4PeopleApp(),
      ),
    );
    expect(find.byType(Connect4PeopleApp), findsOneWidget);
  });
}
