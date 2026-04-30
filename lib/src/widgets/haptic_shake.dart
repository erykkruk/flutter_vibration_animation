import 'package:flutter/material.dart';

import '../haptic_feedback.dart';

/// Wraps a child with an externally-triggered horizontal "wiggle" animation
/// + error notification haptic. The classic "wrong password" shake.
///
/// Trigger via a [GlobalKey]:
///
/// ```dart
/// final shakeKey = GlobalKey<HapticShakeState>();
///
/// HapticShake(key: shakeKey, child: TextField(...))
///
/// // Later, on validation failure:
/// shakeKey.currentState?.shake();
/// ```
///
/// The animation is a 6-segment `TweenSequence` of decreasing-amplitude
/// horizontal translations, ending at zero — feels natural and stops
/// without a visible snap.
class HapticShake extends StatefulWidget {
  const HapticShake({
    super.key,
    required this.child,
    this.amplitude = 10.0,
    this.duration = const Duration(milliseconds: 420),
    this.haptics = true,
  });

  final Widget child;

  /// Maximum horizontal displacement in logical pixels. Subsequent swings
  /// decay from this value.
  final double amplitude;

  /// Total duration of the shake.
  final Duration duration;

  /// Fire `Haptics.notification(error)` at the start of the shake.
  final bool haptics;

  @override
  State<HapticShake> createState() => HapticShakeState();
}

/// State exposed so callers can call [shake] via a `GlobalKey`.
class HapticShakeState extends State<HapticShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _rebuildSequence();
  }

  @override
  void didUpdateWidget(HapticShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amplitude != widget.amplitude) {
      _rebuildSequence();
    }
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  void _rebuildSequence() {
    final a = widget.amplitude;
    // Decaying swings: -1.0, +1.0, -0.8, +0.6, -0.3, 0
    final stops = <double>[0, -a, a, -a * 0.8, a * 0.6, -a * 0.3, 0];
    final items = <TweenSequenceItem<double>>[];
    for (var i = 0; i < stops.length - 1; i++) {
      items.add(
        TweenSequenceItem<double>(
          tween: Tween(begin: stops[i], end: stops[i + 1])
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
      );
    }
    _offset = TweenSequence<double>(items).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Plays the shake animation once. Calling [shake] while already shaking
  /// restarts from the beginning.
  Future<void> shake() async {
    if (widget.haptics) {
      Haptics.notification(HapticNotificationStyle.error);
    }
    await _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) => Transform.translate(
        offset: Offset(_offset.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
