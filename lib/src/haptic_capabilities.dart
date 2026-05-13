import 'method_channel.dart';

/// Snapshot of what the current device can do.
///
/// Use [HapticCapabilities.query] once on app start (or on the first user
/// interaction) and cache the result — values do not change at runtime.
class HapticCapabilities {
  const HapticCapabilities({
    required this.hasVibrator,
    required this.hasAmplitudeControl,
    required this.supportsCustomPatterns,
    required this.supportsPredefinedEffects,
    required this.supportsImpactFeedback,
  });

  /// Device has any kind of vibrator hardware.
  final bool hasVibrator;

  /// Device can render variable-amplitude waveforms.
  ///
  /// * Android — `Vibrator.hasAmplitudeControl()` (API 26+).
  /// * iOS — `true` when Core Haptics is available.
  final bool hasAmplitudeControl;

  /// Device supports custom [HapticPattern]s with intensity + sharpness.
  ///
  /// * Android — true on API 26+ with amplitude control.
  /// * iOS — true on devices with Core Haptics (iPhone 8+).
  final bool supportsCustomPatterns;

  /// Device supports `VibrationEffect.createPredefined` (Android API 29+).
  /// Always `false` on iOS — predefined calls are translated to the closest
  /// `UIImpactFeedbackGenerator` style instead.
  final bool supportsPredefinedEffects;

  /// Device supports `UIImpactFeedbackGenerator` style taps.
  ///
  /// * iOS — true on iOS 10+.
  /// * Android — true on API 23+ via the lightweight `HapticFeedbackConstants`
  ///   path, even on devices without an amplitude-controlled vibrator.
  final bool supportsImpactFeedback;

  /// Read the current device's capabilities.
  static Future<HapticCapabilities> query() async {
    final raw = await HapticKitChannel.invoke<Map<Object?, Object?>>(
      'capabilities.query',
    );
    final map = raw ?? const <Object?, Object?>{};
    return HapticCapabilities(
      hasVibrator: (map['hasVibrator'] as bool?) ?? false,
      hasAmplitudeControl: (map['hasAmplitudeControl'] as bool?) ?? false,
      supportsCustomPatterns: (map['supportsCustomPatterns'] as bool?) ?? false,
      supportsPredefinedEffects:
          (map['supportsPredefinedEffects'] as bool?) ?? false,
      supportsImpactFeedback: (map['supportsImpactFeedback'] as bool?) ?? false,
    );
  }

  @override
  String toString() => 'HapticCapabilities('
      'hasVibrator: $hasVibrator, '
      'hasAmplitudeControl: $hasAmplitudeControl, '
      'supportsCustomPatterns: $supportsCustomPatterns, '
      'supportsPredefinedEffects: $supportsPredefinedEffects, '
      'supportsImpactFeedback: $supportsImpactFeedback)';
}
