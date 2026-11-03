// Compile together with EngineRestartTracker.swift and run the binary:
//
//   swiftc darwin/haptic_kit/Sources/haptic_kit/EngineRestartTracker.swift \
//     test/native/engine_restart/main.swift -o /tmp/engine_restart_test
//   /tmp/engine_restart_test

import Foundation

struct EngineStartFailure: Error {}

var failures = 0

func check(_ condition: Bool, _ description: String) {
    if !condition {
        failures += 1
        print("FAIL: \(description)")
    }
}

func test(_ name: String, _ body: (EngineRestartTracker) -> Void) {
    let before = failures
    body(EngineRestartTracker())
    print("\(failures == before ? "ok  " : "FAIL") \(name)")
}

test("play does not start an engine that was never stopped") { tracker in
    var starts = 0
    try? tracker.restartForPlay { starts += 1 }
    check(starts == 0, "expected no start, got \(starts)")
}

test("play restarts a stopped engine exactly once") { tracker in
    var starts = 0
    tracker.markNeedsStart()
    try? tracker.restartForPlay { starts += 1 }
    try? tracker.restartForPlay { starts += 1 }
    check(starts == 1, "expected one start, got \(starts)")
    check(!tracker.needsStart, "restart should no longer be pending")
}

test("failed restart on play is rethrown and retried on the next play") { tracker in
    var thrown = false
    tracker.markNeedsStart()
    do {
        try tracker.restartForPlay { throw EngineStartFailure() }
    } catch {
        thrown = error is EngineStartFailure
    }
    check(thrown, "the start failure should reach the caller")
    check(tracker.needsStart, "a failed restart should stay pending")

    var starts = 0
    try? tracker.restartForPlay { starts += 1 }
    check(starts == 1, "the next play should retry, got \(starts) starts")
}

test("stop arriving during a restart on play is not lost") { tracker in
    tracker.markNeedsStart()
    try? tracker.restartForPlay { tracker.markNeedsStart() }
    check(tracker.needsStart, "a stop during start() should keep the restart pending")
}

test("reset restarts the engine and clears a pending restart") { tracker in
    var starts = 0
    tracker.markNeedsStart()
    tracker.restartAfterReset { starts += 1 }
    check(starts == 1, "expected one start, got \(starts)")
    check(!tracker.needsStart, "restart should no longer be pending")
}

test("reset restarts the engine even when no stop was seen") { tracker in
    var starts = 0
    tracker.restartAfterReset { starts += 1 }
    check(starts == 1, "expected one start, got \(starts)")
}

test("failed restart after a reset is retried on the next play") { tracker in
    tracker.restartAfterReset { throw EngineStartFailure() }
    check(tracker.needsStart, "a failed reset restart should stay pending")

    var starts = 0
    try? tracker.restartForPlay { starts += 1 }
    check(starts == 1, "the next play should retry, got \(starts) starts")
}

test("stop arriving during a restart after a reset is not lost") { tracker in
    tracker.restartAfterReset { tracker.markNeedsStart() }
    check(tracker.needsStart, "a stop during start() should keep the restart pending")
}

if failures > 0 {
    print("\(failures) check(s) failed")
    exit(1)
}
print("All engine restart tests passed")
