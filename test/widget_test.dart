import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unipool/start_page.dart'; // ✅ Your real project name

void main() {
  testWidgets('Start Frame shows UNIPOOL text', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Start(), // ✅ Class name must match exactly
      ),
    );

    // Check if text exists
    expect(find.text('UNIPOOL'), findsOneWidget);
    expect(find.text('WELCOME TO'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });
}
