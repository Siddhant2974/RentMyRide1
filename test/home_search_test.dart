import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentmyride_app/main.dart';

void main() {
  testWidgets('HomePage search filters car list', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    // Initially both Nashik cars should be present in the horizontal list
    expect(find.text('Toyota Innova Crysta'), findsOneWidget);
    expect(find.text('Maruti Swift'), findsOneWidget);

    // Enter search query that matches 'Swift'
    await tester.enterText(find.byType(TextField), 'Swift');
    await tester.pumpAndSettle();

    // Now only Maruti Swift should be visible
    expect(find.text('Maruti Swift'), findsOneWidget);
    expect(find.text('Toyota Innova Crysta'), findsNothing);
  });
}
