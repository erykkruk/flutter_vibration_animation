import 'haptic_pattern.dart';
import 'vibration.dart';

/// Collection of ready-to-use waveforms and haptic patterns.
///
/// Each entry returns a `Future<void>` so you can `await` playback in UI
/// callbacks:
///
/// ```dart
/// await VibrationPatterns.heartbeat();
/// ```
class VibrationPatterns {
  const VibrationPatterns._();

  /// Two short pulses mimicking a heartbeat.
  static Future<void> heartbeat() => Vibration.vibrateWaveform(
        timings: const [
          Duration.zero,
          Duration(milliseconds: 100),
          Duration(milliseconds: 100),
          Duration(milliseconds: 100),
          Duration(milliseconds: 600),
        ],
        amplitudes: const [0, 200, 0, 200, 0],
      );

  /// Three escalating pulses — typical incoming-notification pattern.
  static Future<void> notification() => Vibration.vibrateWaveform(
        timings: const [
          Duration.zero,
          Duration(milliseconds: 80),
          Duration(milliseconds: 80),
          Duration(milliseconds: 120),
          Duration(milliseconds: 80),
          Duration(milliseconds: 180),
        ],
        amplitudes: const [0, 120, 0, 180, 0, 255],
      );

  /// Long ringing pattern — alarms / incoming calls. Loops by default.
  static Future<void> alarm({bool repeat = true}) => Vibration.vibrateWaveform(
        timings: const [
          Duration.zero,
          Duration(milliseconds: 400),
          Duration(milliseconds: 200),
          Duration(milliseconds: 400),
          Duration(milliseconds: 600),
        ],
        amplitudes: const [0, 255, 0, 255, 0],
        repeat: repeat ? 0 : -1,
      );

  /// Single very short tick — useful for scrub/scroll tactile feedback when
  /// you want something a hair stronger than `HapticFeedback.selection`.
  static Future<void> tick() => Vibration.vibrate(
        duration: const Duration(milliseconds: 10),
        amplitude: 80,
      );

  /// Confirmation: light tap → strong tap.
  static Future<void> success() => HapticPattern.builder()
      .tap(intensity: 0.5, sharpness: 0.5)
      .pause(const Duration(milliseconds: 80))
      .tap(intensity: 1.0, sharpness: 0.8)
      .play();

  /// Failure / cancel: two strong taps.
  static Future<void> failure() => HapticPattern.builder()
      .tap(intensity: 1.0, sharpness: 0.9)
      .pause(const Duration(milliseconds: 120))
      .tap(intensity: 1.0, sharpness: 0.9)
      .play();

  /// Long ramp from soft to strong — useful for "charging up" UI moments.
  static Future<void> chargeUp({
    Duration duration = const Duration(milliseconds: 600),
  }) =>
      HapticPattern.builder()
          .continuous(
            duration: duration,
            intensity: 1.0,
            sharpness: 0.2,
          )
          .play();
}
