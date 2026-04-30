import 'method_channel.dart';

/// Style of an impact tap.
///
/// Maps to:
/// * iOS — `UIImpactFeedbackGenerator.FeedbackStyle`
/// * Android — `VibrationEffect.EFFECT_*` predefined effects (API 29+),
///   or a short `oneShot` fallback on older devices.
enum HapticImpactStyle {
  /// Subtle tap. iOS: `.light`. Android: `EFFECT_TICK`.
  light,

  /// Standard tap. iOS: `.medium`. Android: `EFFECT_CLICK`.
  medium,

  /// Strong tap. iOS: `.heavy`. Android: `EFFECT_HEAVY_CLICK`.
  heavy,

  /// Soft tap (iOS 13+). Falls back to [light] on older iOS / Android.
  soft,

  /// Rigid tap (iOS 13+). Falls back to [heavy] on older iOS / Android.
  rigid,
}

/// Style of a notification haptic.
///
/// Maps to `UINotificationFeedbackGenerator.FeedbackType` on iOS, and to a
/// distinctive short waveform on Android.
enum HapticNotificationStyle {
  /// Confirms a successful action.
  success,

  /// Warns the user about a non-fatal issue.
  warning,

  /// Signals a failure.
  error,
}

/// Short, semantic haptic taps tied to UI events.
///
/// For longer vibrations, custom waveforms or repeating patterns use
/// `Vibration` or [HapticPattern] instead.
///
/// ```dart
/// await Haptics.impact(HapticImpactStyle.medium);
/// await Haptics.notification(HapticNotificationStyle.success);
/// await Haptics.selection();
/// ```
///
/// Named `Haptics` (not `HapticFeedback`) to avoid clashing with Flutter's
/// own `HapticFeedback` from `package:flutter/services.dart`.
class Haptics {
  const Haptics._();

  /// Trigger an impact-style tap.
  ///
  /// On iOS the generator is automatically prepared — repeated calls within
  /// a short window are cheap. On Android API 29+ the matching predefined
  /// effect is used; on older devices a short `oneShot` fallback runs.
  static Future<void> impact(
    HapticImpactStyle style,
  ) =>
      FlutterVibrationAnimationChannel.invoke<void>('haptic.impact', {
        'style': style.name,
      });

  /// Trigger a notification haptic — success / warning / error.
  static Future<void> notification(
    HapticNotificationStyle style,
  ) =>
      FlutterVibrationAnimationChannel.invoke<void>('haptic.notification', {
        'style': style.name,
      });

  /// Trigger a selection-changed tap. Use when scrolling through discrete
  /// values (pickers, sliders, segmented controls).
  static Future<void> selection() =>
      FlutterVibrationAnimationChannel.invoke<void>('haptic.selection');

  /// Pre-warm haptic generators so the next call has the lowest possible
  /// latency. Optional — calling [impact] / [notification] / [selection]
  /// directly works fine.
  ///
  /// Ignored on Android (no equivalent API).
  static Future<void> prepare() =>
      FlutterVibrationAnimationChannel.invoke<void>('haptic.prepare');
}
