package dev.erykkruk.flutter_vibration_animation

/**
 * Translates Dart-side `HapticImpactStyle` / `HapticNotificationStyle` enum
 * names into the closest Android equivalent. Android does not have a direct
 * counterpart to `UIImpactFeedbackGenerator`, so we layer:
 *
 * 1. `VibrationEffect.createPredefined` (API 29+) for impact styles, then
 * 2. short `createOneShot` calls (API 26+) with style-specific durations and
 *    amplitudes, falling back to legacy `Vibrator.vibrate(long)` on older
 *    devices.
 */
internal class HapticFeedbackHandler(private val vibrationManager: VibrationManager) {

    fun impact(style: String) {
        when (style) {
            "light", "soft" -> vibrationManager.predefined("tick")
            "medium" -> vibrationManager.predefined("click")
            "heavy", "rigid" -> vibrationManager.predefined("heavyClick")
            else -> throw IllegalArgumentException("Unknown impact style: $style")
        }
    }

    fun notification(style: String) {
        when (style) {
            // Two short pulses, ascending.
            "success" -> vibrationManager.waveform(
                longArrayOf(0, 60, 60, 80),
                intArrayOf(0, 120, 0, 200),
                -1,
            )
            // Single mid pulse + short tail.
            "warning" -> vibrationManager.waveform(
                longArrayOf(0, 100, 80, 100),
                intArrayOf(0, 180, 0, 180),
                -1,
            )
            // Three rapid heavy taps.
            "error" -> vibrationManager.waveform(
                longArrayOf(0, 80, 60, 80, 60, 100),
                intArrayOf(0, 255, 0, 255, 0, 255),
                -1,
            )
            else -> throw IllegalArgumentException("Unknown notification style: $style")
        }
    }

    fun selection() {
        vibrationManager.predefined("tick")
    }
}
