# haptic_kit

[![pub package](https://img.shields.io/pub/v/haptic_kit.svg)](https://pub.dev/packages/haptic_kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**Haptic feedback, vibration and animated UI widgets** for Flutter — full
Android & iOS implementations covering everything from quick UI taps to
custom Core Haptics patterns with intensity and sharpness curves, plus a
set of production-ready widgets wired to the right haptic at the right
moment.

> Previously developed under the names `flutter_vibration_animation` and
> `flutter_haptics`. The repository URL is unchanged — only the package
> name and class identifiers were updated for consistency with the actual
> surface and pub.dev naming rules.

---

## Features

- **`Haptics`** — short, semantic taps (named `Haptics` to avoid clashing with Flutter's own `HapticFeedback`)
  - Impact: `light`, `medium`, `heavy`, `soft`, `rigid`
  - Notification: `success`, `warning`, `error`
  - Selection (for pickers, sliders, segmented controls)
  - `prepare()` to pre-warm generators on iOS for lowest latency
    (returns `true` on iOS, `false` no-op on Android)
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
  haptic_kit: ^1.0.0
```

### Android

The plugin's `AndroidManifest.xml` already declares `VIBRATE` — nothing else to do.

### iOS

`CoreHaptics`, `UIKit` and `AudioToolbox` are linked automatically through
the podspec. Minimum deployment target: iOS 12.0.

## Quick start

```dart
import 'package:haptic_kit/haptic_kit.dart';

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

The library ships with a set of drop-in widgets that combine an animation
with the right haptic at the right moment. Each one is a single
self-contained file in `lib/src/widgets/` — read one, copy the pattern.

| Widget | What it does | Pattern |
|--------|--------------|---------|
| [`HapticBounce`](#hapticbounce--tactile-bounce-on-tap) | Tap → squash → recoil → elastic settle | 3-segment `TweenSequence`, controller-driven |
| [`PressAndHoldToConfirm`](#pressandholdtoconfirm--long-press-with-progress-ring) | Hold to confirm with ring + densifying ticks | One controller drives ring + haptics + callback |
| `HapticToggle` | Animated switch + tick on flip | Custom-painted thumb with `easeOutBack` slide |
| `HapticSlider` | Slider with detent ticks | Detect detent crossings via `lastIndex` cache |
| `HapticStepper` | −/+ counter with bouncing buttons | Composes `HapticBounce` + `AnimatedSwitcher` |
| `HapticShake` | Wiggle + error notification | Externally triggered via `GlobalKey<State>.shake()` |
| `SlideToConfirm` | Drag handle to end to confirm | Drag-driven controller with snap-back |
| `HapticRating` | Tap a star → cascading fill + tick per star | Sequenced `Timer.periodic` |

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

`pressedScale` must be in `(0, 1)` and `overshootScale` must be `>= 1.0`
— violations throw `ArgumentError` at construction time, both in debug
and release.

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

### `HapticToggle` — animated switch with selection tick

```dart
HapticToggle(
  value: _enabled,
  onChanged: (v) => setState(() => _enabled = v),
)
```

### `HapticSlider` — slider with detent ticks

```dart
HapticSlider(
  value: _v,
  min: 0,
  max: 100,
  divisions: 10,                              // tick every 10 units
  onChanged: (v) => setState(() => _v = v),
)
```

### `HapticStepper` — bouncy −/+ counter

```dart
HapticStepper(
  value: _count,
  min: 0,
  max: 99,
  onChanged: (v) => setState(() => _count = v),
)
```

### `HapticShake` — error wiggle

```dart
final shakeKey = GlobalKey<HapticShakeState>();

HapticShake(key: shakeKey, child: TextField(/* ... */));

// On validation failure:
shakeKey.currentState?.shake();
```

### `SlideToConfirm` — drag-to-confirm pill

```dart
SlideToConfirm(
  label: 'Slide to pay',
  onConfirmed: () => pay(),
)
```

Light ticks at 25%, 50%, 75% of drag, heavy thump on completion. Releasing
before the end snaps back with a light tick.

### `HapticRating` — cascading stars

```dart
HapticRating(
  value: _rating,
  starCount: 5,
  onChanged: (v) => setState(() => _rating = v),
)
```

Tapping the 4th star fires 4 selection ticks in sequence (one per star
"lighting up"), driven by a `Timer.periodic` with a 65ms cascade delay.

## Building your own widget

The widgets above are intentionally small (~100–200 lines each). To add
a new one, follow this pattern:

1. **One file per widget** in `lib/src/widgets/your_widget.dart`.
2. **Pick one of three pickers for what to do per gesture**:
   - **Tap** — `GestureDetector(onTapDown / onTapUp / onTap / onTapCancel)`
     when you want the press-down + release lifecycle.
   - **Long-press / hold** — raw `Listener` so you get
     `onPointerDown` / `onPointerUp` / `event.localPosition` immediately
     and can implement single-pointer guards.
   - **Drag** — `GestureDetector(onHorizontalDragUpdate / End)` for
     anything slidey, or a draggable handle.
3. **One `AnimationController` per widget**, driving everything that
   needs to stay in sync (visual change + haptic schedule + callbacks).
   Avoid running a `Timer` alongside an `AnimationController` — they
   drift, and the user feels the drift.
4. **Fire haptics from the `addListener` callback**, gated by a "what was
   the last threshold I crossed" cursor (`int _lastIndex`, `Set<double>
   _fired`). `while` loops, not `if`, so a stuttered frame still fires
   every tick it crossed.
5. **Pick the right haptic for the moment** — see the table below.
6. **Cancel cleanly**: stop the controller, reset cursors, snap value
   back to zero. Atomic, in one method.
7. **Export from the barrel** in `lib/haptic_kit.dart`.
8. **Write a widget test** — see `test/widgets_test.dart` for the
   pattern (mock the channel with `messenger.setMockMethodCallHandler`).

### Picking the right haptic

| Moment | Haptic | Why |
|--------|--------|-----|
| Crossing a discrete step (slider, picker, page) | `Haptics.selection()` | Quietest tap — never fatiguing |
| Press-down on a button | `Haptics.impact(light)` | Subtle "I felt your touch" |
| Release / tap completes | `Haptics.impact(medium)` | The "click" |
| Long-press completes / drag confirms | `Haptics.impact(heavy)` | Closes the loop with weight |
| Validation passed | `Haptics.notification(success)` | Two-tap pattern, recognisable |
| Soft error / boundary hit | `Haptics.notification(warning)` | Three-tap warning pattern |
| Hard error / wrong input | `Haptics.notification(error)` | Sharp triple-tap |
| Continuous waveform / heartbeat | `Vibration.vibrateWaveform(...)` | When duration matters more than crispness |
| Custom intensity + sharpness curve | `HapticPattern.builder()...play()` | Core Haptics on iOS, amplitude on Android |

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
