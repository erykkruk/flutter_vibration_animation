import 'package:flutter/material.dart';

import '../haptic_feedback.dart';

/// Wraps a child with a looping "breathing" scale pulse, firing a haptic tap
/// on every beat. The attention-getter counterpart to the one-shot
/// [HapticShake] — use it to draw the eye to a call-to-action, an unread
/// badge or a recording indicator.
///
/// Each pulse scales the child `minScale → maxScale → minScale` and fires
/// `Haptics.impact(impactStyle)` at the start of the beat. Pulsing loops
/// forever by default; pass [pulseCount] to stop after a fixed number of
/// beats.
///
/// By default it starts pulsing as soon as it mounts ([autoPlay]). For manual
/// control, set `autoPlay: false` and drive it via a [GlobalKey]:
///
/// ```dart
/// final pulseKey = GlobalKey<HapticPulseState>();
///
/// HapticPulse(
///   key: pulseKey,
///   autoPlay: false,
///   child: const Icon(Icons.notifications),
/// )
///
/// // Later, when something needs attention:
/// pulseKey.currentState?.start();
/// // ...and when it no longer does:
/// pulseKey.currentState?.stop();
/// ```
///
/// Because an infinite pulse never settles, tests covering a `HapticPulse`
/// with the default (infinite) [pulseCount] must drive the clock with
/// `tester.pump(duration)` rather than `tester.pumpAndSettle()`.
class HapticPulse extends StatefulWidget {
  const HapticPulse({
    super.key,
    required this.child,
    this.minScale = 1.0,
    this.maxScale = 1.08,
    this.period = const Duration(milliseconds: 600),
    this.autoPlay = true,
    this.pulseCount,
    this.impactStyle = HapticImpactStyle.light,
    this.haptics = true,
  })  : assert(minScale > 0, 'minScale must be > 0'),
        assert(maxScale > 0, 'maxScale must be > 0'),
        assert(
          pulseCount == null || pulseCount > 0,
          'pulseCount must be null (infinite) or > 0',
        );

  /// The widget to pulse.
  final Widget child;

  /// Scale at the trough of each pulse (the resting scale). Defaults to `1.0`.
  final double minScale;

  /// Scale at the peak of each pulse. Defaults to `1.08`.
  final double maxScale;

  /// Duration of a single `minScale → maxScale → minScale` beat.
  /// Defaults to `600 ms`.
  final Duration period;

  /// Start pulsing automatically as soon as the widget mounts.
  /// Defaults to `true`.
  final bool autoPlay;

  /// Number of beats to play before stopping. `null` (the default) loops
  /// forever until [HapticPulseState.stop] is called.
  final int? pulseCount;

  /// Impact style fired at the start of every beat. Defaults to
  /// [HapticImpactStyle.light].
  final HapticImpactStyle impactStyle;

  /// Fire a haptic impact on each beat. Set to `false` for a silent,
  /// visual-only pulse.
  final bool haptics;

  @override
  State<HapticPulse> createState() => HapticPulseState();
}

/// State exposed so callers can [start] / [stop] pulsing via a `GlobalKey`.
class HapticPulseState extends State<HapticPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;

  bool _pulsing = false;
  int _completed = 0;

  /// Whether the widget is currently pulsing.
  bool get isPulsing => _pulsing;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period);
    _rebuildSequence();
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) start();
      });
    }
  }

  @override
  void didUpdateWidget(HapticPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minScale != widget.minScale ||
        oldWidget.maxScale != widget.maxScale) {
      _rebuildSequence();
    }
    if (oldWidget.period != widget.period) {
      _controller.duration = widget.period;
    }
  }

  void _rebuildSequence() {
    // minScale → maxScale (weight 1) → minScale (weight 1), symmetric ease.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.minScale, end: widget.maxScale)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: widget.maxScale, end: widget.minScale)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Starts (or restarts) pulsing from the first beat. A no-op if already
  /// pulsing.
  void start() {
    if (_pulsing) return;
    _pulsing = true;
    _completed = 0;
    _runCycle();
  }

  /// Stops pulsing and snaps the child back to [HapticPulse.minScale].
  void stop() {
    _pulsing = false;
    _controller
      ..stop()
      ..value = 0;
  }

  Future<void> _runCycle() async {
    if (!_pulsing) return;
    if (widget.haptics) {
      Haptics.impact(widget.impactStyle);
    }
    await _controller.forward(from: 0);
    if (!mounted || !_pulsing) return;
    _completed++;
    if (widget.pulseCount != null && _completed >= widget.pulseCount!) {
      _pulsing = false;
      return;
    }
    _runCycle();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
