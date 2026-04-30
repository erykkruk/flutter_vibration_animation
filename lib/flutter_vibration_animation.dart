/// Comprehensive vibration and haptic feedback for Flutter — Android & iOS.
///
/// Public surface:
///
/// * [Haptics] — short, semantic taps (impact, notification, selection).
/// * [Vibration] — longer vibrations, custom waveforms, predefined effects.
/// * [HapticPattern] — fluent builder for custom event sequences
///   (Core Haptics on iOS, waveform on Android).
/// * [VibrationPatterns] — ready-made patterns (heartbeat, alarm, …).
/// * [HapticCapabilities] — runtime capability detection.
library flutter_vibration_animation;

export 'src/exceptions.dart';
export 'src/haptic_capabilities.dart';
export 'src/haptic_feedback.dart';
export 'src/haptic_pattern.dart';
export 'src/predefined_effect.dart';
export 'src/vibration.dart';
export 'src/vibration_patterns.dart';
