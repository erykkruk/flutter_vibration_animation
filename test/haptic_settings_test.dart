import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_kit/haptic_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('dev.erykkruk/haptic_kit');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    HapticSettings.enabled = true;
    HapticSettings.resetCapabilitiesCache();
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
      if (call.method == 'haptic.prepare') return true;
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    HapticSettings.enabled = true;
    HapticSettings.resetCapabilitiesCache();
  });

  group('HapticSettings.enabled', () {
    test('defaults to enabled', () {
      expect(HapticSettings.enabled, isTrue);
    });

    test('haptics reach the platform while enabled', () async {
      await Haptics.impact(HapticImpactStyle.light);
      await Haptics.notification(HapticNotificationStyle.success);
      await Haptics.selection();

      expect(
        calls.map((c) => c.method),
        ['haptic.impact', 'haptic.notification', 'haptic.selection'],
      );
    });

    test('disabling skips the platform call entirely', () async {
      HapticSettings.enabled = false;

      await Haptics.impact(HapticImpactStyle.heavy);
      await Haptics.notification(HapticNotificationStyle.error);
      await Haptics.selection();

      // Not "called and ignored": a user who turned haptics off should cost
      // no platform calls at all.
      expect(calls, isEmpty);
    });

    test('disabled calls still complete normally', () async {
      HapticSettings.enabled = false;

      // The call sites are UI callbacks; throwing here would be worse than
      // doing nothing.
      await expectLater(
        Haptics.impact(HapticImpactStyle.medium),
        completes,
      );
    });

    test('vibration is suppressed too', () async {
      HapticSettings.enabled = false;

      await Vibration.vibrate(duration: const Duration(milliseconds: 40));

      expect(calls, isEmpty);
    });

    test('ready-made patterns are suppressed', () async {
      HapticSettings.enabled = false;

      await VibrationPatterns.doubleTap();

      expect(calls, isEmpty);
    });

    test('re-enabling resumes playback', () async {
      HapticSettings.enabled = false;
      await Haptics.selection();
      expect(calls, isEmpty);

      HapticSettings.enabled = true;
      await Haptics.selection();

      expect(calls.map((c) => c.method), ['haptic.selection']);
    });

    test('cancel still reaches the platform while disabled', () async {
      // Stopping something already running is not playback; refusing to
      // cancel would leave the device buzzing after the user opted out.
      HapticSettings.enabled = false;

      await Vibration.cancel();

      expect(calls.map((c) => c.method), ['vibration.cancel']);
    });

    test('capability queries still reach the platform while disabled',
        () async {
      HapticSettings.enabled = false;

      final capabilities = await HapticSettings.capabilities;

      expect(calls.map((c) => c.method), ['capabilities.query']);
      expect(capabilities.hasVibrator, isTrue);
    });
  });

  group('HapticSettings.capabilities', () {
    test('queries the platform once and caches the answer', () async {
      final first = await HapticSettings.capabilities;
      final second = await HapticSettings.capabilities;

      final queries = calls.where((c) => c.method == 'capabilities.query');
      expect(queries, hasLength(1));
      expect(identical(first, second), isTrue);
    });

    test('cachedCapabilities is null until the first read', () async {
      expect(HapticSettings.cachedCapabilities, isNull);

      await HapticSettings.capabilities;

      expect(HapticSettings.cachedCapabilities, isNotNull);
    });

    test('resetting the cache makes the next read query again', () async {
      await HapticSettings.capabilities;
      HapticSettings.resetCapabilitiesCache();
      await HapticSettings.capabilities;

      final queries = calls.where((c) => c.method == 'capabilities.query');
      expect(queries, hasLength(2));
    });

    test('a failed query is not cached', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        throw PlatformException(code: 'error', message: 'boom');
      });

      await expectLater(HapticSettings.capabilities, throwsA(isA<Exception>()));

      // A transient failure must not pin an "unsupported" answer for the
      // rest of the session.
      expect(HapticSettings.cachedCapabilities, isNull);
    });

    test('HapticCapabilities.query still bypasses the cache', () async {
      await HapticSettings.capabilities;
      await HapticCapabilities.query();

      final queries = calls.where((c) => c.method == 'capabilities.query');
      expect(queries, hasLength(2));
    });
  });

  group('HapticSettings.isAvailable', () {
    test('is true on a device with a vibrator', () async {
      expect(await HapticSettings.isAvailable, isTrue);
    });

    test('is false while disabled, without querying the device', () async {
      HapticSettings.enabled = false;

      expect(await HapticSettings.isAvailable, isFalse);
      expect(calls, isEmpty);
    });

    test('is false on a device with no vibrator', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return <String, Object?>{'hasVibrator': false};
      });

      expect(await HapticSettings.isAvailable, isFalse);
    });
  });
}
