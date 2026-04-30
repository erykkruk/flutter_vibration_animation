# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
