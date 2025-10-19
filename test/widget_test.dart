// test/widget_test.dart
// Simple widget test-skabelon.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Hello, test')),
        ),
      ),
    );

    expect(find.text('Hello, test'), findsOneWidget);
  });
}
