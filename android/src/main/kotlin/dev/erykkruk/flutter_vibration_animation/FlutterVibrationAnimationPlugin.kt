package dev.erykkruk.flutter_vibration_animation

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FlutterVibrationAnimationPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private companion object {
        const val CHANNEL_NAME = "dev.erykkruk/flutter_vibration_animation"
    }

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var vibrationManager: VibrationManager
    private lateinit var hapticHandler: HapticFeedbackHandler

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        vibrationManager = VibrationManager(context)
        hapticHandler = HapticFeedbackHandler(vibrationManager)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        vibrationManager.cancel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "haptic.impact" -> {
                    val style = call.argument<String>("style")
                        ?: return result.error("invalid_argument", "style missing", null)
                    hapticHandler.impact(style)
                    result.success(null)
                }
                "haptic.notification" -> {
                    val style = call.argument<String>("style")
                        ?: return result.error("invalid_argument", "style missing", null)
                    hapticHandler.notification(style)
                    result.success(null)
                }
                "haptic.selection" -> {
                    hapticHandler.selection()
                    result.success(null)
                }
                "haptic.prepare" -> {
                    // No-op on Android — UIFeedbackGenerator has no equivalent.
                    result.success(null)
                }
                "vibration.oneShot" -> {
                    val durationMs = call.argument<Int>("durationMs")?.toLong()
                        ?: return result.error("invalid_argument", "durationMs missing", null)
                    val amplitude = call.argument<Int>("amplitude")
                    vibrationManager.oneShot(durationMs, amplitude)
                    result.success(null)
                }
                "vibration.waveform" -> {
                    val timings = call.argument<List<Int>>("timingsMs")
                        ?: return result.error("invalid_argument", "timingsMs missing", null)
                    val amplitudes = call.argument<List<Int>>("amplitudes")
                    val repeat = call.argument<Int>("repeat") ?: -1
                    vibrationManager.waveform(
                        timings.map { it.toLong() }.toLongArray(),
                        amplitudes?.toIntArray(),
                        repeat,
                    )
                    result.success(null)
                }
                "vibration.predefined" -> {
                    val effect = call.argument<String>("effect")
                        ?: return result.error("invalid_argument", "effect missing", null)
                    vibrationManager.predefined(effect)
                    result.success(null)
                }
                "vibration.cancel" -> {
                    vibrationManager.cancel()
                    result.success(null)
                }
                "pattern.play" -> {
                    @Suppress("UNCHECKED_CAST")
                    val events = call.argument<List<Map<String, Any?>>>("events")
                        ?: return result.error("invalid_argument", "events missing", null)
                    vibrationManager.playPattern(events)
                    result.success(null)
                }
                "capabilities.query" -> {
                    result.success(vibrationManager.capabilities())
                }
                else -> result.notImplemented()
            }
        } catch (e: UnsupportedOperationException) {
            result.error("unsupported", e.message, null)
        } catch (e: IllegalArgumentException) {
            result.error("invalid_argument", e.message, null)
        } catch (e: Exception) {
            result.error("native_error", e.message, e.stackTraceToString())
        }
    }
}
