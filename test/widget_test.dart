// This is a basic Flutter widget test.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cmc/main.dart'; // Imports your CMCApp

void main() {
  testWidgets('CMCApp MainScreen UI Test', (WidgetTester tester) async {
    // Build our app (CMCApp) and trigger a frame.
    await tester.pumpWidget(const CMCApp());

    // Verify that the AppBar title is present.
    expect(find.text('CMC Home Page'), findsOneWidget);

    // Verify that the welcome message is present.
    expect(find.text('Welcome to CMC Application!'), findsOneWidget);

    // Verify that the "Explore CMC" button is present.
    expect(find.widgetWithText(ElevatedButton, 'Explore CMC'), findsOneWidget);

    // You can also test interactions, for example, tapping the button:
    await tester.tap(find.widgetWithText(ElevatedButton, 'Explore CMC'));
    await tester.pump(); // Allow time for UI to update (e.g., SnackBar)

    // If you want to verify the SnackBar (optional, can be more complex)
    // await tester.pump(const Duration(seconds: 1)); // Wait for SnackBar to appear
    // expect(find.text('CMC Button Tapped!'), findsOneWidget);
  });
}
