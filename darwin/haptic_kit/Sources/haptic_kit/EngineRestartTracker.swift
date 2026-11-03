/// Tracks whether the Core Haptics engine must be started again before the next
/// play. iOS stops the engine when the app is suspended, on audio-session
/// interrupts and on idle timeout, so a play must never assume it is running.
///
/// Kept free of CoreHaptics so the rules can be tested without haptic hardware.
internal final class EngineRestartTracker {

    private(set) var needsStart = false

    func markNeedsStart() {
        needsStart = true
    }

    /// Runs `start` when a restart is pending. A failure stays pending, so the
    /// next play retries it instead of leaving haptics silent for good.
    func restartForPlay(_ start: () throws -> Void) throws {
        guard needsStart else { return }
        // Cleared first: the engine handlers run off the main thread, so a stop
        // arriving during start() must not be overwritten.
        needsStart = false
        do {
            try start()
        } catch {
            needsStart = true
            throw error
        }
    }

    /// Runs `start` after an engine reset. A reset can arrive while the app
    /// cannot start the engine, for example when suspended, and there is no
    /// caller to report that to, so a failure only leaves the restart pending.
    func restartAfterReset(_ start: () throws -> Void) {
        needsStart = false
        do {
            try start()
        } catch {
            needsStart = true
        }
    }
}
