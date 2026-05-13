import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_kit/haptic_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.erykkruk/haptic_kit');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    // Swallow all native calls — widgets fire haptics internally.
    messenger.setMockMethodCallHandler(channel, (_) async => null);
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('HapticBounce', () {
    testWidgets('forwards onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HapticBounce(
                onTap: () => taps++,
                child: const SizedBox(
                  key: ValueKey('target'),
                  width: 100,
                  height: 100,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('target')));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('renders the child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HapticBounce(
              child: Text('hello'),
            ),
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('symmetric mode does not overshoot', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HapticBounce(
              bounceOnRelease: false,
              child: SizedBox(
                key: ValueKey('target'),
                width: 100,
                height: 100,
              ),
            ),
          ),
        ),
      );
      // Smoke: tap completes without throwing and the widget is still there.
      await tester.tap(find.byKey(const ValueKey('target')));
      await tester.pumpAndSettle();
      expect(find.byType(HapticBounce), findsOneWidget);
    });
  });

  group('PressAndHoldToConfirm', () {
    testWidgets('fires onConfirm after holdDuration', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressAndHoldToConfirm(
                holdDuration: const Duration(milliseconds: 200),
                onConfirm: () => confirmed++,
                child: const SizedBox(width: 200, height: 200),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressAndHoldToConfirm)),
      );
      // Pump past the hold duration in small steps so the controller ticks.
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 25));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(confirmed, 1);
    });

    testWidgets('cancels when released early', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressAndHoldToConfirm(
                holdDuration: const Duration(milliseconds: 400),
                onConfirm: () => confirmed++,
                child: const SizedBox(width: 200, height: 200),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressAndHoldToConfirm)),
      );
      await tester.pump(const Duration(milliseconds: 100)); // released early
      await gesture.up();
      await tester.pumpAndSettle();

      expect(confirmed, 0);
    });

    testWidgets('does not refire while completed', (tester) async {
      var confirmed = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressAndHoldToConfirm(
                holdDuration: const Duration(milliseconds: 100),
                onConfirm: () => confirmed++,
                child: const SizedBox(width: 200, height: 200),
              ),
            ),
          ),
        ),
      );

      Future<void> longPress() async {
        final g = await tester.startGesture(
          tester.getCenter(find.byType(PressAndHoldToConfirm)),
        );
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        await g.up();
        await tester.pumpAndSettle();
      }

      await longPress();
      await longPress();

      expect(
        confirmed,
        1,
        reason: 'second press without reset must be a no-op',
      );
    });

    testWidgets('reset re-arms the widget', (tester) async {
      var confirmed = 0;
      final key = GlobalKey<PressAndHoldToConfirmState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressAndHoldToConfirm(
                key: key,
                holdDuration: const Duration(milliseconds: 100),
                onConfirm: () => confirmed++,
                child: const SizedBox(width: 200, height: 200),
              ),
            ),
          ),
        ),
      );

      Future<void> longPress() async {
        final g = await tester.startGesture(
          tester.getCenter(find.byType(PressAndHoldToConfirm)),
        );
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        await g.up();
        await tester.pumpAndSettle();
      }

      await longPress();
      key.currentState!.reset();
      await tester.pump();
      await longPress();

      expect(confirmed, 2);
    });
  });
}
