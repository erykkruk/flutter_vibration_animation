// Smoke test for the haptic_kit example app.
//
// Verifies the demo app boots and renders its main screen without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:haptic_kit_example/main.dart';

void main() {
  testWidgets('VibrationDemoApp boots and renders the demo screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const VibrationDemoApp());

    // The demo page shows an AppBar titled with the package name.
    expect(find.text('haptic_kit'), findsOneWidget);
    expect(find.byType(VibrationDemoPage), findsOneWidget);
  });
}
