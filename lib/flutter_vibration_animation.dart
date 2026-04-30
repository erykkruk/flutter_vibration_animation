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
/// * [HapticBounce] — drop-in tap wrapper with squash + elastic bounce.
/// * [PressAndHoldToConfirm] — long-press confirmation with progress
///   ring + densifying haptic schedule.
library flutter_vibration_animation;

export 'src/exceptions.dart';
export 'src/haptic_capabilities.dart';
export 'src/haptic_feedback.dart';
export 'src/haptic_pattern.dart';
export 'src/predefined_effect.dart';
export 'src/vibration.dart';
export 'src/vibration_patterns.dart';
export 'src/widgets/haptic_bounce.dart';
export 'src/widgets/press_and_hold_to_confirm.dart';
