import 'package:flutter/material.dart';

import '../haptic_feedback.dart';

/// Long-press confirmation widget — the user must hold their finger on
/// [child] for [holdDuration] to trigger [onConfirm].
///
/// While pressed, a circular progress ring renders at the finger position
/// and a sequence of haptic ticks fires at progressively shorter intervals,
/// escalating from `selection` → `light` → `medium` → `heavy`. On
/// completion a final `heavy` impact lands together with [onConfirm].
///
/// Releasing early snaps the ring back to zero, resets the haptic
/// sequence, and the gesture can be retried. Once [onConfirm] has fired,
/// further presses are ignored until [reset] is called.
///
/// ```dart
/// PressAndHoldToConfirm(
///   holdDuration: const Duration(seconds: 2),
///   onConfirm: () => unbox(),
///   child: const SizedBox(
///     height: 240,
///     child: Center(child: Icon(Icons.lock, size: 96)),
///   ),
/// )
/// ```
///
/// Architecture: a single [AnimationController] drives the ring, the
/// haptic schedule, and the completion callback — keeping all three
/// perfectly in sync. Pointer events are captured with a raw [Listener]
/// (not [GestureDetector]) so the press starts immediately, the live
/// finger position is available, and a single-pointer guard rejects
/// secondary touches that would otherwise restart the animation.
class PressAndHoldToConfirm extends StatefulWidget {
  const PressAndHoldToConfirm({
    super.key,
    required this.child,
    required this.onConfirm,
    this.holdDuration = const Duration(seconds: 2),
    this.ringSize = 96,
    this.ringStrokeWidth = 6,
    this.ringColor,
    this.showRingAtFingerPosition = true,
  });

  /// The widget rendered under the finger (typically the thing being
  /// "unlocked" or "unboxed").
  final Widget child;

  /// Fired exactly once when the press completes. Use [reset] to allow
  /// another confirmation.
  final VoidCallback onConfirm;

  /// How long the user must hold to trigger confirmation.
  /// Defaults to 2 seconds.
  final Duration holdDuration;

  /// Diameter of the progress ring in logical pixels.
  final double ringSize;

  /// Stroke width of the progress ring.
  final double ringStrokeWidth;

  /// Ring colour. Defaults to `Theme.colorScheme.primary`.
  final Color? ringColor;

  /// When `true` the ring follows the finger. When `false` it renders
  /// centred over [child] — useful for fixed-position "press here" buttons.
  final bool showRingAtFingerPosition;

  @override
  State<PressAndHoldToConfirm> createState() => PressAndHoldToConfirmState();
}

/// State exposed so callers can call [reset] via a `GlobalKey`.
class PressAndHoldToConfirmState extends State<PressAndHoldToConfirm>
    with SingleTickerProviderStateMixin {
  // 12 progress thresholds at which a haptic tick fires. Gaps shrink in
  // time so the user feels the press *accelerating* even though the
  // controller advances linearly.
  //
  // start ~0.11 apart  →  middle ~0.09  →  end ~0.05–0.04
  static const List<double> _hapticPoints = [
    0.07, 0.18, 0.30, 0.42, // start
    0.52, 0.61, 0.70, 0.78, // middle
    0.84, 0.89, 0.93, 0.97, // end
  ];

  late final AnimationController _hold;
  int _activePointer = -1;
  int _hapticIndex = 0;
  Offset? _ringPosition;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _hold = AnimationController(vsync: this, duration: widget.holdDuration)
      ..addListener(_onProgress)
      ..addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(PressAndHoldToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.holdDuration != widget.holdDuration) {
      _hold.duration = widget.holdDuration;
    }
  }

  @override
  void dispose() {
    _hold
      ..removeListener(_onProgress)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  /// Re-arms the widget after a successful confirmation. Has no effect
  /// while a press is in progress or before the first confirmation.
  void reset() {
    if (_activePointer != -1) return;
    setState(() {
      _completed = false;
      _hapticIndex = 0;
      _ringPosition = null;
      _hold.value = 0;
    });
  }

  void _onProgress() {
    final progress = _hold.value;
    // `while` (not `if`) so a stuttered frame that crosses two thresholds
    // at once still fires both ticks — costs nothing if it never happens.
    while (_hapticIndex < _hapticPoints.length &&
        progress >= _hapticPoints[_hapticIndex]) {
      _fireHapticAt(_hapticPoints[_hapticIndex]);
      _hapticIndex++;
    }
  }

  void _fireHapticAt(double progress) {
    if (progress < 0.35) {
      Haptics.selection();
    } else if (progress < 0.80) {
      Haptics.impact(HapticImpactStyle.light);
    } else if (progress < 0.95) {
      Haptics.impact(HapticImpactStyle.medium);
    } else {
      Haptics.impact(HapticImpactStyle.heavy);
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_completed) {
      _completed = true;
      // Final "lock-in" tap — without this the last in-list tick (at 0.97)
      // would be the closing feeling and completion would land softly.
      Haptics.impact(HapticImpactStyle.heavy);
      widget.onConfirm();
    }
  }

  void _start(PointerDownEvent event) {
    if (_completed) return;
    if (_activePointer != -1) return; // single-pointer guard
    _activePointer = event.pointer;
    _hapticIndex = 0;
    setState(() => _ringPosition = event.localPosition);
    _hold.forward(from: 0);
  }

  void _cancel(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = -1;
    if (_completed) return;
    if (_hold.status == AnimationStatus.completed) return;
    _hapticIndex = 0;
    _hold
      ..stop()
      ..value = 0;
    setState(() => _ringPosition = null);
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.ringColor ?? Theme.of(context).colorScheme.primary;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _start,
      onPointerUp: _cancel,
      onPointerCancel: _cancel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // IgnorePointer so the child cannot consume touches that the
          // outer Listener wants to track.
          IgnorePointer(child: widget.child),
          if (_ringPosition != null)
            Positioned(
              left: widget.showRingAtFingerPosition
                  ? _ringPosition!.dx - widget.ringSize / 2
                  : null,
              top: widget.showRingAtFingerPosition
                  ? _ringPosition!.dy - widget.ringSize / 2
                  : null,
              right: widget.showRingAtFingerPosition ? null : 0,
              bottom: widget.showRingAtFingerPosition ? null : 0,
              child: IgnorePointer(
                child: SizedBox(
                  width: widget.ringSize,
                  height: widget.ringSize,
                  child: AnimatedBuilder(
                    animation: _hold,
                    builder: (context, _) => CircularProgressIndicator(
                      value: _hold.value,
                      strokeWidth: widget.ringStrokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                      backgroundColor: ringColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
