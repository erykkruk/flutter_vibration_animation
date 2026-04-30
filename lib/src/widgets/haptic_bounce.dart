import 'package:flutter/material.dart';

import '../haptic_feedback.dart';

/// Tactile press-down with elastic bounce-back, optionally synchronised with
/// haptic feedback.
///
/// In `bounceOnRelease: true` mode (the default) the scale follows a
/// 3-segment `TweenSequence`:
///
/// 1. **squash** — `1.0 → pressedScale`, `easeIn`, weight 1
/// 2. **recoil** — `pressedScale → overshootScale` (overshoots 1.0),
///    `easeOutCubic`, weight 2
/// 3. **settle** — `overshootScale → 1.0`, `elasticOut`, weight 3
///
/// The press-down animation runs through segment 1 only. Releasing plays
/// segments 2 and 3 — recoil + elastic settle. A press cancelled mid-way
/// (finger dragged off) animates back through segment 1 without
/// overshooting.
///
/// In `bounceOnRelease: false` mode the scale is a plain symmetric
/// `1.0 → pressedScale → 1.0` press with no overshoot.
///
/// ```dart
/// HapticBounce(
///   onTap: () => doSomething(),
///   child: Container(
///     padding: const EdgeInsets.all(24),
///     decoration: const BoxDecoration(/* ... */),
///     child: const Text('Press me'),
///   ),
/// )
/// ```
class HapticBounce extends StatefulWidget {
  const HapticBounce({
    super.key,
    required this.child,
    this.onTap,
    this.bounceOnRelease = true,
    this.pressedScale = 0.92,
    this.overshootScale = 1.12,
    this.pressDuration = const Duration(milliseconds: 110),
    this.releaseDuration = const Duration(milliseconds: 480),
    this.haptics = true,
    this.behavior = HitTestBehavior.opaque,
  })  : assert(
          pressedScale > 0 && pressedScale < 1.0,
          'pressedScale must be in (0, 1)',
        ),
        assert(
          overshootScale >= 1.0,
          'overshootScale must be >= 1.0',
        );

  /// The widget to scale on press.
  final Widget child;

  /// Called when the user taps successfully (after the press-down + release
  /// sequence is initiated). Equivalent to `GestureDetector.onTap`.
  final VoidCallback? onTap;

  /// When `true`, releasing plays a recoil + elastic-settle bounce.
  /// When `false`, scale returns symmetrically to 1.0 with no overshoot.
  final bool bounceOnRelease;

  /// Scale at the bottom of the press. Defaults to `0.92`.
  final double pressedScale;

  /// Peak scale reached during the recoil phase. Defaults to `1.12`.
  /// Ignored when [bounceOnRelease] is `false`.
  final double overshootScale;

  /// Duration of the press-down animation. Defaults to `110 ms`.
  final Duration pressDuration;

  /// Duration of the release animation (recoil + elastic settle).
  /// Defaults to `480 ms` — short enough to feel snappy, long enough for
  /// `Curves.elasticOut` to fully resolve without looking glitchy.
  final Duration releaseDuration;

  /// Fire `Haptics.impact(light)` on press-down and `medium` on release.
  /// Set to `false` for a silent visual-only bounce.
  final bool haptics;

  /// Hit-test behaviour passed to the underlying [GestureDetector].
  final HitTestBehavior behavior;

  @override
  State<HapticBounce> createState() => _HapticBounceState();
}

class _HapticBounceState extends State<HapticBounce>
    with SingleTickerProviderStateMixin {
  // Press-down target on the controller, expressed as a value in 0..1.
  //
  // For the bounce sequence, segment (1) has weight 1 out of 1+2+3=6, so the
  // end of segment (1) — the fully-pressed state — sits at 1/6.
  static const double _kBounceShrunkValue = 1 / 6;

  // For the symmetric sequence (1→pressed, pressed→1, both weight 1), the
  // pressed state sits at the midpoint.
  static const double _kSymmetricShrunkValue = 0.5;

  late final AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _rebuildSequence();
  }

  @override
  void didUpdateWidget(HapticBounce oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bounceOnRelease != widget.bounceOnRelease ||
        oldWidget.pressedScale != widget.pressedScale ||
        oldWidget.overshootScale != widget.overshootScale) {
      _rebuildSequence();
    }
  }

  void _rebuildSequence() {
    if (widget.bounceOnRelease) {
      _scale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: widget.pressedScale)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: widget.pressedScale,
            end: widget.overshootScale,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
          weight: 2,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: widget.overshootScale, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 3,
        ),
      ]).animate(_controller);
    } else {
      _scale = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: widget.pressedScale)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: widget.pressedScale, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
      ]).animate(_controller);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    // Snap to rest before re-pressing — without this, a rapid tap during a
    // still-running release animation would resume from a random scale and
    // feel non-deterministic.
    _controller.value = 0;
    final target =
        widget.bounceOnRelease ? _kBounceShrunkValue : _kSymmetricShrunkValue;
    _controller.animateTo(target, duration: widget.pressDuration);
    if (widget.haptics) {
      Haptics.impact(HapticImpactStyle.light);
    }
  }

  Future<void> _up(TapUpDetails _) async {
    if (widget.haptics) {
      Haptics.impact(HapticImpactStyle.medium);
    }
    await _controller.animateTo(1, duration: widget.releaseDuration);
  }

  Future<void> _cancel() async {
    await _controller.animateBack(0, duration: widget.pressDuration);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _down,
      onTapUp: _up,
      onTap: widget.onTap,
      onTapCancel: _cancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
