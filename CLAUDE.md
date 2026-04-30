# flutter_vibration_animation

## Overview

Flutter plugin z pełną implementacją wibracji i haptic feedback dla Android i iOS — od krótkich UI tapów (UIImpactFeedbackGenerator / HapticFeedbackConstants) po custom patterny Core Haptics (intensity + sharpness) i waveformy z amplitudą.

## Tech Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter | >= 3.10.0 |
| Language | Dart | >= 3.0.0 |
| Android | Kotlin | 1.9.0 |
| Android API | minSdk 21, compileSdk 34 | — |
| iOS | Swift | 5.0 |
| iOS deployment | iOS 12.0 | — |
| Linting | flutter_lints | ^4.0.0 |

## Development Commands

```bash
flutter pub get          # Dependencies
flutter analyze          # Static analysis
dart format .            # Format
flutter test             # Tests
cd example && flutter run  # Run demo
```

## Directory Structure

```
flutter_vibration_animation/
├── lib/
│   ├── flutter_vibration_animation.dart   # Barrel — public API
│   └── src/
│       ├── exceptions.dart                # Typed exceptions
│       ├── haptic_capabilities.dart       # Runtime detection
│       ├── haptic_feedback.dart           # Impact/notification/selection
│       ├── haptic_pattern.dart            # Core Haptics pattern builder
│       ├── method_channel.dart            # MethodChannel wrapper (private)
│       ├── predefined_effect.dart         # Predefined enum
│       ├── vibration.dart                 # One-shot, waveform, predefined
│       └── vibration_patterns.dart        # Ready-made patterns
├── android/
│   ├── build.gradle
│   └── src/main/
│       ├── AndroidManifest.xml            # VIBRATE permission
│       └── kotlin/dev/erykkruk/flutter_vibration_animation/
│           ├── FlutterVibrationAnimationPlugin.kt
│           ├── HapticFeedbackHandler.kt
│           └── VibrationManager.kt
├── ios/
│   ├── flutter_vibration_animation.podspec
│   └── Classes/
│       ├── FlutterVibrationAnimationPlugin.swift
│       ├── HapticFeedbackHandler.swift   # UIFeedbackGenerator wrapper
│       └── CoreHapticsHandler.swift      # CHHapticEngine wrapper
├── test/
├── example/
└── .github/workflows/
    ├── ci.yml
    ├── auto-tag.yml
    └── publish.yml
```

## Architecture Pattern

**Method Channel Plugin** (no FFI):

1. Dart wraps each domain (`HapticFeedback`, `Vibration`, `HapticPattern`) as
   a static class calling `FlutterVibrationAnimationChannel.invoke`.
2. `method_channel.dart` is a private singleton that translates
   `PlatformException` → typed `VibrationException` subclasses.
3. Native side dispatches by method name and uses small handler classes:
   - **Android:** `HapticFeedbackHandler` (predefined effects + waveforms),
     `VibrationManager` (Vibrator API wrapper with API-level branching).
   - **iOS:** `HapticFeedbackHandler` (UIKit feedback generators),
     `CoreHapticsHandler` (CHHapticEngine for custom patterns + waveforms).

### Channel name

`dev.erykkruk/flutter_vibration_animation` — used by both sides.

### Method names

| Method | Args | Purpose |
|--------|------|---------|
| `haptic.impact` | `style` | UIImpact / Android predefined |
| `haptic.notification` | `style` | UINotification / Android waveform |
| `haptic.selection` | — | UISelection / Android tick |
| `haptic.prepare` | — | iOS prewarm (no-op on Android) |
| `vibration.oneShot` | `durationMs`, `amplitude?` | Single vibration |
| `vibration.waveform` | `timingsMs`, `amplitudes?`, `repeat` | Custom waveform |
| `vibration.predefined` | `effect` | EFFECT_TICK / CLICK / DOUBLE_CLICK / HEAVY_CLICK |
| `vibration.cancel` | — | Stop any running vibration |
| `pattern.play` | `events` | Core Haptics events with intensity + sharpness |
| `capabilities.query` | — | Returns capabilities map |

## Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `haptic_pattern.dart` |
| Dart classes | PascalCase | `HapticPattern` |
| Kotlin classes | PascalCase | `VibrationManager` |
| Swift classes | PascalCase | `CoreHapticsHandler` |
| Channel methods | dot.namespace | `vibration.waveform` |
| Channel args | camelCase | `durationMs`, `relativeTimeMs` |

## Error Handling

```dart
sealed class VibrationException implements Exception { … }
class InvalidVibrationArgumentException extends VibrationException { … }
class UnsupportedHapticException extends VibrationException { … }
class PlatformVibrationException extends VibrationException { String? code; … }
```

Native errors map by code:
- `invalid_argument` → `InvalidVibrationArgumentException`
- `unsupported` → `UnsupportedHapticException`
- everything else → `PlatformVibrationException`

## Anti-Patterns

### NIGDY

1. Bezpośrednie wywołania `MethodChannel` w API publicznym — zawsze przez
   `FlutterVibrationAnimationChannel.invoke` (uniformizuje obsługę błędów).
2. Surowe `throw Exception(…)` — zawsze typed `VibrationException`.
3. Mutable global state w warstwie Dart — pluginy są singleton po stronie
   native, ale Dart API jest stateless (tylko `HapticPattern.builder` ma
   stan i jest świeży per-instance).
4. Brak walidacji parametrów na granicy publicznego API.
5. `print()` w library code.
6. Hardcoded magic numbers — wszystkie progi / konwersje (255, 0.5, …) mają
   uzasadnienie w komentarzach lub stałych (`kMaxAmplitude`, `kMinAmplitude`).
7. Pełzanie API: nowy native call wymaga jednoczesnej zmiany Dart + Kotlin
   + Swift. Zawsze trzy strony naraz, inaczej krzyż w CI.

### ZAWSZE

1. Capability detection przed użyciem nieuniwersalnych funkcji
   (`HapticCapabilities.query`).
2. Fallback path na każdej platformie — nigdy crash, w najgorszym razie
   silent no-op lub `UnsupportedHapticException`.
3. `///` doc comments na publicznym API z przykładami.
4. Nazwy enumów = string identifiers przekazywane przez channel
   (`HapticImpactStyle.medium.name == "medium"`) — żadnych map konwersji
   po stronie Dart.
5. API-level branching w Kotlinie (`Build.VERSION.SDK_INT >= O / Q / S`).
6. iOS `@available(iOS 13.0, *)` dookoła Core Haptics + soft/rigid impact.
7. Test po każdej zmianie publicznego API.

## New Feature Checklist

1. [ ] Zaprojektuj API w Dart (klasa + doc comments + przykład)
2. [ ] Dodaj method handler w `FlutterVibrationAnimationPlugin.kt`
3. [ ] Zaimplementuj logikę w odpowiednim handlerze (Android)
4. [ ] Dodaj method handler w `FlutterVibrationAnimationPlugin.swift`
5. [ ] Zaimplementuj logikę w odpowiednim handlerze (iOS) z fallbackiem
6. [ ] Zaktualizuj `HapticCapabilities` jeśli to nowa zdolność
7. [ ] Eksport w `flutter_vibration_animation.dart`
8. [ ] Test mockujący `MethodChannel`
9. [ ] Demo w `example/lib/main.dart`
10. [ ] Update README + CHANGELOG
11. [ ] `flutter analyze` — zero warnings

## Claude Code Integration

| Type | Name | Purpose |
|------|------|---------|
| Command | `/commit` | Conventional commit |
| Command | `/pr` | Pull request |
| Command | `/review` | Code review routing |
| Command | `/quality-check` | analyze + format + test |
