/// Platform-provided vibration effects.
///
/// Maps to `VibrationEffect.EFFECT_*` constants on Android API 29+, and to
/// the closest [HapticFeedback] style on iOS / older Android.
enum PredefinedEffect {
  /// A single very short tick — UI cue (Android: `EFFECT_TICK`).
  tick,

  /// A single short click (Android: `EFFECT_CLICK`).
  click,

  /// A double click (Android: `EFFECT_DOUBLE_CLICK`).
  doubleClick,

  /// A single strong click (Android: `EFFECT_HEAVY_CLICK`).
  heavyClick,
}
