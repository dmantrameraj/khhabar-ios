// Smoke test — verifies the app boots without crashing and the bottom
// navigation shell renders its four tabs. Deliberately does not wait for
// the real network call to resolve (that would make this test depend on
// live internet/API availability); asserting the initial loading state is
// enough to prove the widget tree builds correctly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:khhabar_app/main.dart';

void main() {
  testWidgets('App boots and shows the bottom navigation shell', (WidgetTester tester) async {
    await tester.pumpWidget(const KhhabarApp());

    // Before the network call resolves, the home tab shows a spinner —
    // proves the widget tree built without throwing.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // The four bottom-nav destinations are present.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
