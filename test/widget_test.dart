// This is a basic Flutter widget test for the PetLover app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:petlover/main.dart';

void main() {
  testWidgets('PetLover loads and shows title smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PetLoverApp());

    // Verify that our title "PetLover" is present.
    expect(find.text('PetLover'), findsWidgets);
  });
}

