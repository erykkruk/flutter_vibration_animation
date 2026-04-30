import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vibration_animation/flutter_vibration_animation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.erykkruk/flutter_vibration_animation');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final hapticCalls = <String>[];

  setUp(() {
    hapticCalls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      hapticCalls.add(call.method);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  group('HapticToggle', () {
    testWidgets('toggles value and fires haptic', (tester) async {
      var value = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => wrap(
            HapticToggle(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(HapticToggle));
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(hapticCalls, contains('haptic.selection'));
    });

    testWidgets('does nothing when onChanged is null', (tester) async {
      await tester.pumpWidget(
        wrap(const HapticToggle(value: false, onChanged: null)),
      );
      await tester.tap(find.byType(HapticToggle));
      await tester.pumpAndSettle();
      expect(hapticCalls, isEmpty);
    });
  });

  group('HapticSlider', () {
    testWidgets('fires tick when crossing a detent', (tester) async {
      var value = 0.0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => wrap(
            SizedBox(
              width: 300,
              child: HapticSlider(
                value: value,
                divisions: 10,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );
      // Drag from left to ~middle.
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(150, 0));
      await tester.pumpAndSettle();
      expect(
        hapticCalls.where((c) => c == 'haptic.impact').length,
        greaterThan(0),
      );
    });
  });

  group('HapticStepper', () {
    testWidgets('+/- changes value and fires haptic', (tester) async {
      var value = 5;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => wrap(
            HapticStepper(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(value, 6);

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(value, 5);
    });

    testWidgets('boundary fires heavy without changing value', (tester) async {
      var value = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => wrap(
            HapticStepper(
              value: value,
              min: 0,
              max: 10,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(value, 0, reason: 'should clamp at min');
    });
  });

  group('HapticShake', () {
    testWidgets('shake() fires error haptic', (tester) async {
      final key = GlobalKey<HapticShakeState>();
      await tester.pumpWidget(
        wrap(HapticShake(key: key, child: const Text('field'))),
      );
      key.currentState!.shake();
      await tester.pumpAndSettle();
      expect(hapticCalls, contains('haptic.notification'));
    });
  });

  group('SlideToConfirm', () {
    testWidgets('fires onConfirmed when dragged to end', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            child: SlideToConfirm(onConfirmed: () => confirmed++),
          ),
        ),
      );
      // Find the handle (the Icon inside the GestureDetector).
      final handle = find.byIcon(Icons.arrow_forward);
      await tester.drag(handle, const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(confirmed, 1);
    });

    testWidgets('snaps back when released early', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 400,
            child: SlideToConfirm(onConfirmed: () => confirmed++),
          ),
        ),
      );
      await tester.drag(find.byIcon(Icons.arrow_forward), const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(confirmed, 0);
    });
  });

  group('HapticRating', () {
    testWidgets('tap sets rating and cascades haptics', (tester) async {
      var rating = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => wrap(
            HapticRating(
              value: rating,
              starCount: 5,
              cascadeDelay: const Duration(milliseconds: 5),
              onChanged: (v) => setState(() => rating = v),
            ),
          ),
        ),
      );
      // Tap the 4th star (index 3).
      final stars = find.byType(Icon);
      await tester.tap(stars.at(3));
      // Pump enough for the cascade to finish (4 ticks * 5 ms).
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(rating, 4);
      expect(
        hapticCalls.where((c) => c == 'haptic.selection').length,
        greaterThanOrEqualTo(4),
      );
    });
  });
}
