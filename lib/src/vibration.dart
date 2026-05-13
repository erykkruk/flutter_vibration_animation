import 'exceptions.dart';
import 'method_channel.dart';
import 'predefined_effect.dart';

/// Maximum amplitude value (matches Android's `VibrationEffect.MAX_AMPLITUDE`).
const int kMaxAmplitude = 255;

/// Minimum amplitude that still produces a perceptible vibration.
const int kMinAmplitude = 1;

/// Longer-form vibration API — one-shot durations, custom waveforms,
/// predefined OS effects and continuous vibrations.
///
/// For short, UI-event taps prefer `Haptics`. For complex haptic sequences
/// with intensity + sharpness curves use [HapticPattern].
class Vibration {
  const Vibration._();

  /// Vibrate for [duration].
  ///
  /// [amplitude] is in 1..255 range. Values are silently clamped on
  /// devices without amplitude control. Pass `null` to use the device default.
  ///
  /// Throws [InvalidVibrationArgumentException] when [duration] is zero or
  /// negative, or when [amplitude] is set outside `[1, 255]`.
  static Future<void> vibrate({
    required Duration duration,
    int? amplitude,
  }) {
    if (duration.inMilliseconds <= 0) {
      throw const InvalidVibrationArgumentException(
        'duration must be > 0 ms',
      );
    }
    if (amplitude != null &&
        (amplitude < kMinAmplitude || amplitude > kMaxAmplitude)) {
      throw const InvalidVibrationArgumentException(
        'amplitude must be in [$kMinAmplitude, $kMaxAmplitude]',
      );
    }
    return FlutterHapticsChannel.invoke<void>('vibration.oneShot', {
      'durationMs': duration.inMilliseconds,
      if (amplitude != null) 'amplitude': amplitude,
    });
  }

  /// Play a custom waveform.
  ///
  /// [timings] is a list of off/on durations starting with an off period
  /// (Android `createWaveform` convention). [amplitudes], if provided, must
  /// have the same length as [timings] and use values in `[0, 255]`
  /// (`0` = pause).
  ///
  /// Set [repeat] to the index in [timings] from which to loop, or `-1` for
  /// no loop (default).
  ///
  /// On iOS without Core Haptics support the call falls back to a sequence
  /// of system vibrations approximating [timings].
  static Future<void> vibrateWaveform({
    required List<Duration> timings,
    List<int>? amplitudes,
    int repeat = -1,
  }) {
    if (timings.isEmpty) {
      throw const InvalidVibrationArgumentException(
        'timings must not be empty',
      );
    }
    if (amplitudes != null && amplitudes.length != timings.length) {
      throw const InvalidVibrationArgumentException(
        'amplitudes must have the same length as timings',
      );
    }
    if (amplitudes != null) {
      for (final a in amplitudes) {
        if (a < 0 || a > kMaxAmplitude) {
          throw const InvalidVibrationArgumentException(
            'amplitudes must be in [0, $kMaxAmplitude]',
          );
        }
      }
    }
    if (repeat < -1 || repeat >= timings.length) {
      throw const InvalidVibrationArgumentException(
        'repeat must be -1 or a valid index in timings',
      );
    }
    return FlutterHapticsChannel.invoke<void>('vibration.waveform', {
      'timingsMs': timings.map((d) => d.inMilliseconds).toList(),
      if (amplitudes != null) 'amplitudes': amplitudes,
      'repeat': repeat,
    });
  }

  /// Trigger one of the platform's predefined effects.
  ///
  /// On Android API 29+ this uses `VibrationEffect.createPredefined`. On
  /// older Android and on iOS the call is translated to the closest
  /// equivalent on `Haptics` / [vibrate].
  static Future<void> playPredefined(PredefinedEffect effect) =>
      FlutterHapticsChannel.invoke<void>('vibration.predefined', {
        'effect': effect.name,
      });

  /// Stop any vibration started by this plugin.
  static Future<void> cancel() =>
      FlutterHapticsChannel.invoke<void>('vibration.cancel');
}
