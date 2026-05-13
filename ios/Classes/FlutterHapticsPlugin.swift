import Flutter
import UIKit

public class FlutterHapticsPlugin: NSObject, FlutterPlugin {

    private static let channelName = "dev.erykkruk/flutter_haptics"

    private let hapticHandler = HapticFeedbackHandler()
    private let coreHaptics = CoreHapticsHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
        let instance = FlutterHapticsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "haptic.impact":
                let style = try requireString(call, "style")
                hapticHandler.impact(style: style)
                result(nil)

            case "haptic.notification":
                let style = try requireString(call, "style")
                hapticHandler.notification(style: style)
                result(nil)

            case "haptic.selection":
                hapticHandler.selection()
                result(nil)

            case "haptic.prepare":
                hapticHandler.prepare()
                // iOS actually pre-warmed the generators — let Dart know.
                result(true)

            case "vibration.oneShot":
                let durationMs = try requireInt(call, "durationMs")
                let amplitude = (call.arguments as? [String: Any])?["amplitude"] as? Int
                coreHaptics.oneShot(durationMs: durationMs, amplitude: amplitude, fallback: hapticHandler)
                result(nil)

            case "vibration.waveform":
                guard let args = call.arguments as? [String: Any],
                      let timings = args["timingsMs"] as? [Int]
                else {
                    throw PluginError.invalidArgument("timingsMs missing")
                }
                let amplitudes = args["amplitudes"] as? [Int]
                let repeatIndex = args["repeat"] as? Int ?? -1
                coreHaptics.waveform(
                    timingsMs: timings,
                    amplitudes: amplitudes,
                    repeatIndex: repeatIndex,
                    fallback: hapticHandler
                )
                result(nil)

            case "vibration.predefined":
                let effect = try requireString(call, "effect")
                hapticHandler.predefined(effect: effect)
                result(nil)

            case "vibration.cancel":
                coreHaptics.cancel()
                result(nil)

            case "pattern.play":
                guard let args = call.arguments as? [String: Any],
                      let events = args["events"] as? [[String: Any]]
                else {
                    throw PluginError.invalidArgument("events missing")
                }
                try coreHaptics.playPattern(events: events, fallback: hapticHandler)
                result(nil)

            case "capabilities.query":
                result(coreHaptics.capabilities())

            default:
                result(FlutterMethodNotImplemented)
            }
        } catch let PluginError.invalidArgument(msg) {
            result(FlutterError(code: "invalid_argument", message: msg, details: nil))
        } catch let PluginError.unsupported(msg) {
            result(FlutterError(code: "unsupported", message: msg, details: nil))
        } catch {
            result(FlutterError(code: "native_error", message: error.localizedDescription, details: nil))
        }
    }

    // MARK: - Helpers

    private func requireString(_ call: FlutterMethodCall, _ key: String) throws -> String {
        guard let dict = call.arguments as? [String: Any],
              let value = dict[key] as? String
        else {
            throw PluginError.invalidArgument("\(key) missing")
        }
        return value
    }

    private func requireInt(_ call: FlutterMethodCall, _ key: String) throws -> Int {
        guard let dict = call.arguments as? [String: Any],
              let value = dict[key] as? Int
        else {
            throw PluginError.invalidArgument("\(key) missing")
        }
        return value
    }
}

internal enum PluginError: Error {
    case invalidArgument(String)
    case unsupported(String)
}
