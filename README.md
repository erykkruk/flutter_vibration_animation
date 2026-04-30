# flutter_vibration_animation

[![pub package](https://img.shields.io/pub/v/flutter_vibration_animation.svg)](https://pub.dev/packages/flutter_vibration_animation)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Comprehensive **vibration and haptic feedback** for Flutter — full Android & iOS
implementations covering everything from quick UI taps to custom Core Haptics
patterns with intensity and sharpness curves.

---

## Features

- **`Haptics`** — short, semantic taps (named `Haptics` to avoid clashing with Flutter's own `HapticFeedback`)
  - Impact: `light`, `medium`, `heavy`, `soft`, `rigid`
  - Notification: `success`, `warning`, `error`
  - Selection (for pickers, sliders, segmented controls)
  - `prepare()` to pre-warm generators on iOS for lowest latency
- **`Vibration`** — longer-form vibrations
  - One-shot vibration with optional amplitude
  - Custom waveforms with per-segment amplitudes
  - Predefined OS effects (`tick`, `click`, `doubleClick`, `heavyClick`)
  - Cancel any running vibration
- **`HapticPattern`** — fluent builder for **Core Haptics** patterns
  - Transient taps + continuous events
  - Per-event `intensity` and `sharpness` (0.0–1.0)
  - Automatic translation to Android amplitude waveforms
- **`VibrationPatterns`** — ready-made: heartbeat, notification,
  alarm, tick, success, failure, charge-up
- **`HapticCapabilities`** — runtime detection of vibrator hardware,
  amplitude control, Core Haptics, predefined effects
- **`HapticBounce`** — drop-in tap wrapper with squash + recoil + elastic
  settle bounce (3-segment `TweenSequence`), wired to light/medium impact
- **`PressAndHoldToConfirm`** — long-press confirmation with a finger-tracking
  progress ring and a 12-tick densifying haptic schedule that escalates
  from `selection` → `light` → `medium` → `heavy`

## Platform support

| Feature | Android | iOS |
|---------|---------|-----|
| Impact / notification / selection | ✅ API 21+ (best on 26+) | ✅ iOS 10+ |
| One-shot + amplitude | ✅ API 26+ | ✅ iPhone 8+ (Core Haptics) |
| Custom waveforms | ✅ API 26+ | ✅ iPhone 8+ |
| Predefined effects | ✅ API 29+ | ↩︎ mapped to closest impact |
| Custom patterns (intensity + sharpness) | ✅ API 26+ | ✅ iPhone 8+ |
| Capability detection | ✅ | ✅ |

## Installation

```yaml
dependencies:
  flutter_vibration_animation: ^0.1.0
```

### Android

The plugin's `AndroidManifest.xml` already declares `VIBRATE` — nothing else to do.

### iOS

`CoreHaptics`, `UIKit` and `AudioToolbox` are linked automatically through
the podspec. Minimum deployment target: iOS 12.0.

## Quick start

```dart
import 'package:flutter_vibration_animation/flutter_vibration_animation.dart';

// Short UI taps
await Haptics.impact(HapticImpactStyle.medium);
await Haptics.notification(HapticNotificationStyle.success);
await Haptics.selection();

// Longer vibrations
await Vibration.vibrate(duration: const Duration(milliseconds: 300));

// Custom waveform — three pulses with growing amplitude
await Vibration.vibrateWaveform(
  timings: const [
    Duration.zero,
    Duration(milliseconds: 100),
    Duration(milliseconds: 100),
    Duration(milliseconds: 100),
    Duration(milliseconds: 100),
    Duration(milliseconds: 100),
  ],
  amplitudes: const [0, 80, 0, 160, 0, 255],
);

// Predefined OS effect
await Vibration.playPredefined(PredefinedEffect.doubleClick);

// Ready-made pattern
await VibrationPatterns.heartbeat();
```

## Custom haptic patterns (Core Haptics)

```dart
await HapticPattern.builder()
    .tap(intensity: 0.4, sharpness: 0.6)
    .pause(const Duration(milliseconds: 80))
    .tap(intensity: 1.0, sharpness: 0.9)
    .continuous(
      duration: const Duration(milliseconds: 250),
      intensity: 0.7,
      sharpness: 0.3,
    )
    .play();
```

* On **iOS** (iPhone 8+) this renders as a `CHHapticPattern` with
  `hapticTransient` / `hapticContinuous` events.
* On **Android** (API 26+) `intensity` is mapped to amplitude; `sharpness`
  is ignored (no perceptual analogue).
* On older devices, `play()` throws `UnsupportedHapticException` — guard
  with `HapticCapabilities.query()` if you need graceful degradation.

## Animated widgets

### `HapticBounce` — tactile bounce on tap

Wraps any widget with a press-down → recoil → elastic-settle animation
synchronised with a light/medium impact. Drop-in replacement for
`GestureDetector(onTap: …)` on buttons that should feel alive.

```dart
HapticBounce(
  onTap: () => doSomething(),
  child: Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(/* ... */),
    child: const Text('Press me'),
  ),
)
```

The scale follows a 3-segment `TweenSequence` with weights 1 : 2 : 3:

1. **squash** — `1.0 → 0.92`, `easeIn`
2. **recoil** — `0.92 → 1.12` (overshoots 1.0), `easeOutCubic`
3. **settle** — `1.12 → 1.0`, `elasticOut`

Set `bounceOnRelease: false` for a plain symmetric press with no overshoot.

### `PressAndHoldToConfirm` — long-press with progress ring

Requires the user to hold for [holdDuration] before firing `onConfirm`. A
circular progress ring renders at the finger position, and a 12-tick
haptic schedule fires at progressively shorter intervals — escalating
from `selection` → `light` → `medium` → `heavy`, sealed with a final
`heavy` impact at completion.

```dart
final key = GlobalKey<PressAndHoldToConfirmState>();

PressAndHoldToConfirm(
  key: key,
  holdDuration: const Duration(seconds: 2),
  onConfirm: () => unbox(),
  child: const SizedBox(
    height: 240,
    child: Center(child: Icon(Icons.card_giftcard, size: 96)),
  ),
)

// Re-arm for another confirmation later:
key.currentState?.reset();
```

Architecture notes:

* A single `AnimationController` drives the ring, the haptic schedule
  and the completion callback — no race conditions between independent
  timers.
* Pointer events are captured with a raw `Listener` (not `GestureDetector`)
  so the press starts immediately and the live finger position is
  available.
* A single-pointer guard rejects secondary touches that would otherwise
  restart the animation.
* Releasing early snaps the ring back to zero and resets the haptic
  cursor — a re-press starts fresh.

## Capability detection

```dart
final caps = await HapticCapabilities.query();
if (caps.supportsCustomPatterns) {
  await VibrationPatterns.success();
} else {
  await Haptics.notification(HapticNotificationStyle.success);
}
```

## Error handling

All public APIs throw subclasses of `VibrationException`:

| Exception | Thrown when |
|-----------|-------------|
| `InvalidVibrationArgumentException` | A parameter is out of range (negative duration, amplitude > 255, mismatched lists, …) |
| `UnsupportedHapticException` | The device cannot render the requested capability |
| `PlatformVibrationException` | The native side returned an error or the plugin is not registered |

## Example app

A runnable demo lives in [`example/`](example/) — buttons for every kind of
feedback, side by side.

## License

MIT — see [LICENSE](LICENSE).
