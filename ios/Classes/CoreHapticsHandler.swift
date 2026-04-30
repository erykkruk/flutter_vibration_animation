import CoreHaptics
import UIKit

/// Wraps `CHHapticEngine` for custom patterns and waveforms. Falls back to
/// `HapticFeedbackHandler` (UIFeedbackGenerator + AudioServices) on devices
/// without Core Haptics support.
internal final class CoreHapticsHandler {

    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?

    private let supportsHaptics: Bool = {
        if #available(iOS 13.0, *) {
            return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        }
        return false
    }()

    @available(iOS 13.0, *)
    private func ensureEngine() throws -> CHHapticEngine {
        if let existing = engine { return existing }
        let new = try CHHapticEngine()
        new.resetHandler = { [weak self] in
            try? self?.engine?.start()
        }
        new.stoppedHandler = { _ in /* ignore — restart on next call */ }
        try new.start()
        engine = new
        return new
    }

    // MARK: - One-shot vibration

    func oneShot(durationMs: Int, amplitude: Int?, fallback: HapticFeedbackHandler) {
        guard supportsHaptics else {
            // Without Core Haptics we have no way to control duration finely —
            // approximate with a system vibration for >= 200 ms, otherwise tap.
            if durationMs >= 200 {
                fallback.systemVibrate()
            } else {
                fallback.impact(style: amplitude.map { $0 > 170 ? "heavy" : ($0 > 80 ? "medium" : "light") } ?? "medium")
            }
            return
        }
        if #available(iOS 13.0, *) {
            let intensity = amplitude.map { Float($0) / 255.0 } ?? 1.0
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                ],
                relativeTime: 0,
                duration: TimeInterval(durationMs) / 1000.0
            )
            playEvents([event])
        }
    }

    // MARK: - Waveform

    func waveform(timingsMs: [Int], amplitudes: [Int]?, repeatIndex: Int, fallback: HapticFeedbackHandler) {
        guard !timingsMs.isEmpty else { return }

        guard supportsHaptics else {
            // Approximate the waveform with a single system vibration if the
            // total active time is meaningful, otherwise a notification tap.
            let activeMs = zip(timingsMs.indices, timingsMs).reduce(0) { acc, pair in
                let (i, ms) = pair
                let isActive = (amplitudes?[i] ?? (i % 2 == 1 ? 255 : 0)) > 0
                return acc + (isActive ? ms : 0)
            }
            if activeMs >= 200 {
                fallback.systemVibrate()
            } else {
                fallback.impact(style: "medium")
            }
            return
        }

        if #available(iOS 13.0, *) {
            var events: [CHHapticEvent] = []
            var cursorMs = 0
            for (i, ms) in timingsMs.enumerated() {
                let amp = amplitudes?[i] ?? (i % 2 == 1 ? 255 : 0)
                if amp > 0 && ms > 0 {
                    let intensity = Float(amp) / 255.0
                    events.append(CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5),
                        ],
                        relativeTime: TimeInterval(cursorMs) / 1000.0,
                        duration: TimeInterval(ms) / 1000.0
                    ))
                }
                cursorMs += ms
            }
            playEvents(events, loop: repeatIndex >= 0)
        }
    }

    // MARK: - Pattern

    func playPattern(events rawEvents: [[String: Any]], fallback: HapticFeedbackHandler) throws {
        guard supportsHaptics else {
            // Closest approximation: pick the strongest tap.
            let maxIntensity = rawEvents
                .compactMap { ($0["intensity"] as? NSNumber)?.doubleValue }
                .max() ?? 0.5
            let style = maxIntensity > 0.7 ? "heavy" : (maxIntensity > 0.4 ? "medium" : "light")
            fallback.impact(style: style)
            return
        }
        if #available(iOS 13.0, *) {
            var events: [CHHapticEvent] = []
            for raw in rawEvents {
                let intensity = Float((raw["intensity"] as? NSNumber)?.floatValue ?? 1.0)
                let sharpness = Float((raw["sharpness"] as? NSNumber)?.floatValue ?? 0.5)
                let durationMs = (raw["durationMs"] as? NSNumber)?.intValue ?? 0
                let relativeMs = (raw["relativeTimeMs"] as? NSNumber)?.intValue ?? 0
                let params = [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ]
                let event: CHHapticEvent
                if durationMs > 0 {
                    event = CHHapticEvent(
                        eventType: .hapticContinuous,
                        parameters: params,
                        relativeTime: TimeInterval(relativeMs) / 1000.0,
                        duration: TimeInterval(durationMs) / 1000.0
                    )
                } else {
                    event = CHHapticEvent(
                        eventType: .hapticTransient,
                        parameters: params,
                        relativeTime: TimeInterval(relativeMs) / 1000.0
                    )
                }
                events.append(event)
            }
            playEvents(events)
        }
    }

    // MARK: - Cancel

    func cancel() {
        if #available(iOS 13.0, *) {
            try? player?.stop(atTime: CHHapticTimeImmediate)
            player = nil
        }
    }

    // MARK: - Capabilities

    func capabilities() -> [String: Any] {
        return [
            "hasVibrator": true,
            "hasAmplitudeControl": supportsHaptics,
            "supportsCustomPatterns": supportsHaptics,
            "supportsPredefinedEffects": false,
            "supportsImpactFeedback": true,
        ]
    }

    // MARK: - Private

    @available(iOS 13.0, *)
    private func playEvents(_ events: [CHHapticEvent], loop: Bool = false) {
        guard !events.isEmpty else { return }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let engine = try ensureEngine()
            let advanced = try engine.makeAdvancedPlayer(with: pattern)
            advanced.loopEnabled = loop
            try? player?.stop(atTime: CHHapticTimeImmediate)
            player = advanced
            try advanced.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Engine failed — silently swallow rather than crashing the app.
            // Capability flags inform callers whether they can rely on it.
        }
    }
}
