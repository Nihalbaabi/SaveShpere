import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ecotrack/main.dart'; // Adjust path if necessary

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SaveSphereApp());

    // Verify that the app mounts without crashing. We don't need a counter.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
