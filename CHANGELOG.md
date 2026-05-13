# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-05-13

### Changed
- **Package renamed** from `flutter_vibration_animation` to `flutter_haptics`
  to match the actual surface (`Haptics`, `HapticPattern`, `HapticBounce`,
  …) and to surface the library to users searching for haptic feedback
  rather than vibration animations. The GitHub repository keeps its
  original URL.
- Method channel renamed from `dev.erykkruk/flutter_vibration_animation`
  to `dev.erykkruk/flutter_haptics`. Android package and plugin class
  renamed accordingly (`dev.erykkruk.flutter_haptics.FlutterHapticsPlugin`).
  iOS podspec and plugin class renamed (`FlutterHapticsPlugin`).
- `Haptics.prepare()` now returns `Future<bool>` instead of `Future<void>`
  — `true` when the platform actually pre-warmed haptic generators (iOS),
  `false` when the call is a no-op on the current platform (Android).
- `HapticBounce` now validates `pressedScale` (must be in `(0, 1)`) and
  `overshootScale` (must be `>= 1.0`) at runtime, not only in debug. Bad
  values now throw `ArgumentError` instead of silently producing
  inverted scales in release builds.
- Dropped the deprecated `library flutter_vibration_animation;` directive
  from the barrel — modern Dart no longer requires it.
- Barrel-level doc comment now lists all 8 animated widgets, making them
  discoverable via IDE autocompletion on the `flutter_haptics` import.
- Pub.dev topics updated: `haptics`, `vibration`, `haptic-feedback`,
  `animation`, `widgets`.

### Added
- Boundary-condition tests for `InvalidVibrationArgumentException`:
  negative duration, amplitude below `kMinAmplitude`, amplitude above
  `kMaxAmplitude`, amplitude at the upper boundary, empty timings,
  negative waveform amplitude, out-of-range `repeat` index.
- Tests covering the new `Haptics.prepare()` return value for both
  platform paths (iOS true / Android false).
- Test covering the `invalid_argument` platform error code mapping to
  `InvalidVibrationArgumentException`.

## [0.1.0] - 2026-04-30

### Added
- Initial release.
- `Haptics` — impact (light/medium/heavy/soft/rigid), notification
  (success/warning/error), selection, prepare.
- `Vibration` — one-shot, custom waveforms with amplitude control,
  predefined OS effects, cancel.
- `HapticPattern` — fluent builder for Core Haptics events
  (intensity + sharpness, transient + continuous).
- `VibrationPatterns` — heartbeat, notification, alarm, tick, success,
  failure, charge-up.
- `HapticCapabilities` — runtime detection of vibrator hardware,
  amplitude control, Core Haptics, predefined effects.
- Android implementation (Kotlin) with `Vibrator` / `VibratorManager`
  (API 31+), `VibrationEffect.createOneShot` / `createWaveform`
  (API 26+), `createPredefined` (API 29+) and pre-API-26 fallbacks.
- iOS implementation (Swift) with `UIImpactFeedbackGenerator`,
  `UINotificationFeedbackGenerator`, `UISelectionFeedbackGenerator` and
  `CHHapticEngine` for custom patterns. AudioServices fallback for
  devices without Core Haptics.
- `HapticToggle` — animated switch with custom-painted thumb, spring-back
  `easeOutBack` curve and a selection tick on every flip.
- `HapticSlider` — wraps the standard `Slider` and fires a light tick at
  every detent crossing (configurable via `divisions` or `tickEvery`),
  with a heavier tick at the min/max endpoints.
- `HapticStepper` — composes two `HapticBounce` buttons around a sliding
  number; light haptic on each step, heavy haptic when hitting `min`/`max`.
- `HapticShake` — externally-triggered horizontal wiggle animation
  (6-segment decaying `TweenSequence`) with an error notification haptic.
  Triggered via `GlobalKey<HapticShakeState>().shake()`.
- `SlideToConfirm` — drag-to-confirm pill (Uber-style) with light ticks at
  25/50/75% drag, heavy thump on completion, and spring-back with a tick
  on early release. State exposes `reset()` for re-arming.
- `HapticRating` — star row that cascade-fills with one selection tick per
  star when tapped, configurable cascade delay.
- README "Building your own widget" section with the recurring pattern
  (one controller, gated thresholds, atomic cancel) and a table mapping
  each interaction moment to the right haptic.
- `HapticBounce` widget — drop-in tap wrapper with squash + recoil +
  elastic-settle bounce (3-segment `TweenSequence` with weights 1:2:3)
  synchronised with light/medium haptic impacts.
- `PressAndHoldToConfirm` widget — long-press confirmation with a
  finger-tracking progress ring, 12-tick densifying haptic schedule,
  escalating intensity (selection → light → medium → heavy) and a final
  heavy impact on completion. Single `AnimationController` drives the
  ring, haptics and callback in lock-step. Single-pointer guard,
  cancel-on-early-release, and `reset()` for re-arming.
- Showcase example app with five animated demos:
  - Typewriter — auto-typing text with a `selection` tick per character.
  - Heartbeat — pulsing heart icon synced with `VibrationPatterns.heartbeat`.
  - Loading ramp — progress bar 0→100% with light → medium → heavy haptic
    impacts at 25/50/75% and a `success` notification at 100%.
  - Bouncy press — gradient circle wrapped in `HapticBounce`.
  - Press & hold to unbox — gift-box card wrapped in
    `PressAndHoldToConfirm` that opens to a celebration on completion.
