package dev.erykkruk.haptic_kit

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager as AndroidVibratorManager

/**
 * Thin wrapper over [Vibrator] / [AndroidVibratorManager] that hides the API-level
 * differences and clamps amplitudes to the device's capabilities.
 */
internal class VibrationManager(context: Context) {

    private val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val vm = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? AndroidVibratorManager
        vm?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }

    private val hasVibrator: Boolean = vibrator?.hasVibrator() == true

    private val hasAmplitudeControl: Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            vibrator?.hasAmplitudeControl() == true

    fun oneShot(durationMs: Long, amplitude: Int?) {
        val v = vibrator ?: return
        if (!hasVibrator) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val amp = when {
                amplitude == null -> VibrationEffect.DEFAULT_AMPLITUDE
                hasAmplitudeControl -> amplitude.coerceIn(1, 255)
                else -> VibrationEffect.DEFAULT_AMPLITUDE
            }
            v.vibrate(VibrationEffect.createOneShot(durationMs, amp))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(durationMs)
        }
    }

    fun waveform(timings: LongArray, amplitudes: IntArray?, repeat: Int) {
        val v = vibrator ?: return
        if (!hasVibrator) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && hasAmplitudeControl && amplitudes != null) {
            val clamped = IntArray(amplitudes.size) { i -> amplitudes[i].coerceIn(0, 255) }
            v.vibrate(VibrationEffect.createWaveform(timings, clamped, repeat))
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createWaveform(timings, repeat))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(timings, repeat)
        }
    }

    fun predefined(effect: String) {
        val v = vibrator ?: return
        if (!hasVibrator) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val id = when (effect) {
                "tick" -> VibrationEffect.EFFECT_TICK
                "click" -> VibrationEffect.EFFECT_CLICK
                "doubleClick" -> VibrationEffect.EFFECT_DOUBLE_CLICK
                "heavyClick" -> VibrationEffect.EFFECT_HEAVY_CLICK
                else -> throw IllegalArgumentException("Unknown predefined effect: $effect")
            }
            v.vibrate(VibrationEffect.createPredefined(id))
        } else {
            // Pre-API 29 fallback — short oneShot of varying duration.
            val durationMs = when (effect) {
                "tick" -> 10L
                "click" -> 20L
                "doubleClick" -> 50L  // approximated as one slightly longer pulse
                "heavyClick" -> 40L
                else -> throw IllegalArgumentException("Unknown predefined effect: $effect")
            }
            oneShot(durationMs, null)
        }
    }

    fun playPattern(events: List<Map<String, Any?>>) {
        if (events.isEmpty()) return
        val v = vibrator ?: return
        if (!hasVibrator) return

        // Convert haptic events into a (timings, amplitudes) waveform.
        // Android has no perceptual sharpness — we map intensity (0..1) to amplitude (1..255).
        val segments = mutableListOf<Pair<Long, Int>>() // duration to amplitude
        var cursor = 0L
        for (event in events) {
            val intensity = (event["intensity"] as? Number)?.toDouble() ?: 0.0
            val durationMs = (event["durationMs"] as? Number)?.toLong() ?: 0L
            val relativeTime = (event["relativeTimeMs"] as? Number)?.toLong() ?: 0L

            val gap = relativeTime - cursor
            if (gap > 0) {
                segments.add(gap to 0)
                cursor += gap
            }
            val amp = (intensity * 255).toInt().coerceIn(1, 255)
            val effective = if (durationMs <= 0) 20L else durationMs
            segments.add(effective to amp)
            cursor += effective
        }

        val timings = LongArray(segments.size) { segments[it].first }
        val amplitudes = IntArray(segments.size) { segments[it].second }
        waveform(timings, amplitudes, -1)
    }

    fun cancel() {
        vibrator?.cancel()
    }

    fun capabilities(): Map<String, Any> = mapOf(
        "hasVibrator" to hasVibrator,
        "hasAmplitudeControl" to hasAmplitudeControl,
        "supportsCustomPatterns" to (hasVibrator && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O),
        "supportsPredefinedEffects" to (hasVibrator && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q),
        "supportsImpactFeedback" to hasVibrator,
    )
}
