import AudioToolbox
import UIKit

/// Bridges `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator` and
/// `UISelectionFeedbackGenerator` to method-channel string identifiers, with
/// AudioServices fallbacks for very old devices.
internal final class HapticFeedbackHandler {

    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private lazy var lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private lazy var heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)

    @available(iOS 13.0, *)
    private lazy var softGenerator = UIImpactFeedbackGenerator(style: .soft)

    @available(iOS 13.0, *)
    private lazy var rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)

    func impact(style: String) {
        switch style {
        case "light":
            lightGenerator.prepare()
            lightGenerator.impactOccurred()
        case "medium":
            mediumGenerator.prepare()
            mediumGenerator.impactOccurred()
        case "heavy":
            heavyGenerator.prepare()
            heavyGenerator.impactOccurred()
        case "soft":
            if #available(iOS 13.0, *) {
                softGenerator.prepare()
                softGenerator.impactOccurred()
            } else {
                lightGenerator.prepare()
                lightGenerator.impactOccurred()
            }
        case "rigid":
            if #available(iOS 13.0, *) {
                rigidGenerator.prepare()
                rigidGenerator.impactOccurred()
            } else {
                heavyGenerator.prepare()
                heavyGenerator.impactOccurred()
            }
        default:
            break
        }
    }

    func notification(style: String) {
        notificationGenerator.prepare()
        switch style {
        case "success":
            notificationGenerator.notificationOccurred(.success)
        case "warning":
            notificationGenerator.notificationOccurred(.warning)
        case "error":
            notificationGenerator.notificationOccurred(.error)
        default:
            break
        }
    }

    func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }

    func prepare() {
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        if #available(iOS 13.0, *) {
            softGenerator.prepare()
            rigidGenerator.prepare()
        }
    }

    /// Pre-API-Core-Haptics fallback for predefined effects and one-shots.
    func predefined(effect: String) {
        switch effect {
        case "tick":
            selection()
        case "click":
            impact(style: "medium")
        case "doubleClick":
            impact(style: "medium")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.impact(style: "medium")
            }
        case "heavyClick":
            impact(style: "heavy")
        default:
            break
        }
    }

    /// System vibration (~400 ms). Used as a last-resort fallback for
    /// `Vibration.vibrate(...)` when Core Haptics is unavailable.
    func systemVibrate() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
