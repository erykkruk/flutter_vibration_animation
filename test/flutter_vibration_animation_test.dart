import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_vibration_animation/flutter_vibration_animation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.erykkruk/flutter_vibration_animation');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'capabilities.query') {
        return <String, Object?>{
          'hasVibrator': true,
          'hasAmplitudeControl': true,
          'supportsCustomPatterns': true,
          'supportsPredefinedEffects': true,
          'supportsImpactFeedback': true,
        };
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  group('Haptics', () {
    test('impact sends style enum name', () async {
      await Haptics.impact(HapticImpactStyle.heavy);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'haptic.impact');
      expect(calls.single.arguments, {'style': 'heavy'});
    });

    test('notification sends style enum name', () async {
      await Haptics.notification(HapticNotificationStyle.success);
      expect(calls.single.method, 'haptic.notification');
      expect(calls.single.arguments, {'style': 'success'});
    });

    test('selection sends no arguments', () async {
      await Haptics.selection();
      expect(calls.single.method, 'haptic.selection');
      expect(calls.single.arguments, isNull);
    });
  });

  group('Vibration', () {
    test('vibrate validates duration', () {
      expect(
        () => Vibration.vibrate(duration: Duration.zero),
        throwsA(isA<InvalidVibrationArgumentException>()),
      );
    });

    test('vibrate validates amplitude bounds', () {
      expect(
        () => Vibration.vibrate(
          duration: const Duration(milliseconds: 100),
          amplitude: 999,
        ),
        throwsA(isA<InvalidVibrationArgumentException>()),
      );
    });

    test('vibrate sends durationMs and amplitude', () async {
      await Vibration.vibrate(
        duration: const Duration(milliseconds: 250),
        amplitude: 200,
      );
      expect(calls.single.method, 'vibration.oneShot');
      expect(calls.single.arguments, {'durationMs': 250, 'amplitude': 200});
    });

    test('vibrateWaveform validates amplitudes length', () {
      expect(
        () => Vibration.vibrateWaveform(
          timings: const [Duration(milliseconds: 50)],
          amplitudes: const [100, 200],
        ),
        throwsA(isA<InvalidVibrationArgumentException>()),
      );
    });

    test('playPredefined sends effect name', () async {
      await Vibration.playPredefined(PredefinedEffect.doubleClick);
      expect(calls.single.method, 'vibration.predefined');
      expect(calls.single.arguments, {'effect': 'doubleClick'});
    });

    test('cancel sends no args', () async {
      await Vibration.cancel();
      expect(calls.single.method, 'vibration.cancel');
    });
  });

  group('HapticPattern', () {
    test('builder serializes events', () async {
      await HapticPattern.builder()
          .tap(intensity: 0.5, sharpness: 0.7)
          .pause(const Duration(milliseconds: 100))
          .tap(intensity: 1.0, sharpness: 0.3)
          .play();

      expect(calls.single.method, 'pattern.play');
      final args = calls.single.arguments as Map<Object?, Object?>;
      final events = args['events'] as List<Object?>;
      expect(events, hasLength(2));

      final first = events.first as Map<Object?, Object?>;
      expect(first['intensity'], 0.5);
      expect(first['sharpness'], 0.7);
      expect(first['relativeTimeMs'], 0);

      final second = events.last as Map<Object?, Object?>;
      expect(second['intensity'], 1.0);
      expect(second['sharpness'], 0.3);
      expect(second['relativeTimeMs'], 100);
    });

    test('continuous advances cursor', () async {
      await HapticPattern.builder()
          .continuous(
            duration: const Duration(milliseconds: 200),
            intensity: 1.0,
            sharpness: 0.5,
          )
          .tap(intensity: 0.8, sharpness: 0.5)
          .play();

      final events = (calls.single.arguments as Map<Object?, Object?>)['events']
          as List<Object?>;
      final tap = events.last as Map<Object?, Object?>;
      expect(tap['relativeTimeMs'], 200);
    });

    test('empty pattern throws', () {
      expect(
        () => HapticPattern.builder().play(),
        throwsA(isA<InvalidVibrationArgumentException>()),
      );
    });
  });

  group('HapticCapabilities', () {
    test('parses native map', () async {
      final caps = await HapticCapabilities.query();
      expect(caps.hasVibrator, isTrue);
      expect(caps.supportsCustomPatterns, isTrue);
    });
  });

  group('error mapping', () {
    test('platform unsupported maps to UnsupportedHapticException', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'unsupported', message: 'no haptics');
      });
      expect(
        () => Haptics.selection(),
        throwsA(isA<UnsupportedHapticException>()),
      );
    });

    test('missing plugin maps to PlatformVibrationException', () async {
      messenger.setMockMethodCallHandler(channel, null);
      expect(
        () => Haptics.selection(),
        throwsA(isA<PlatformVibrationException>()),
      );
    });
  });
}
