import 'package:flutter/material.dart';

import '../haptic_feedback.dart';

/// Slider that fires a haptic tick whenever the value crosses a discrete
/// detent — like the iOS picker wheel.
///
/// If [divisions] is provided, ticks fire at every step. Otherwise ticks
/// fire at thresholds defined by [tickEvery] (in value units, e.g. every
/// `0.1` for a 0..1 slider).
///
/// ```dart
/// HapticSlider(
///   value: _v,
///   min: 0,
///   max: 100,
///   divisions: 10,                              // tick every 10 units
///   onChanged: (v) => setState(() => _v = v),
/// )
/// ```
class HapticSlider extends StatefulWidget {
  const HapticSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.tickEvery,
    this.label,
    this.activeColor,
    this.tickStyle = HapticImpactStyle.light,
    this.endTickStyle = HapticImpactStyle.medium,
  })  : assert(
          divisions == null || divisions > 0,
          'divisions must be > 0',
        ),
        assert(
          tickEvery == null || tickEvery > 0,
          'tickEvery must be > 0',
        );

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;

  /// Discrete divisions. Mutually exclusive with [tickEvery] in semantics
  /// but if both are set, [divisions] wins.
  final int? divisions;

  /// Distance between ticks in value units (used when [divisions] is null).
  final double? tickEvery;

  final String? label;
  final Color? activeColor;

  /// Haptic style for intermediate ticks.
  final HapticImpactStyle tickStyle;

  /// Haptic style for the min and max endpoints.
  final HapticImpactStyle endTickStyle;

  @override
  State<HapticSlider> createState() => _HapticSliderState();
}

class _HapticSliderState extends State<HapticSlider> {
  int _lastDetent = -1;

  /// Returns the detent index for [value], or `-1` if no detent grid is
  /// configured.
  int _detentIndexFor(double value) {
    if (widget.divisions != null) {
      final t = (value - widget.min) / (widget.max - widget.min);
      return (t * widget.divisions!).round();
    }
    if (widget.tickEvery != null) {
      return ((value - widget.min) / widget.tickEvery!).round();
    }
    return -1;
  }

  void _onChanged(double v) {
    final detent = _detentIndexFor(v);
    if (detent != -1 && detent != _lastDetent) {
      _lastDetent = detent;
      final atEdge = v == widget.min || v == widget.max;
      Haptics.impact(atEdge ? widget.endTickStyle : widget.tickStyle);
    }
    widget.onChanged(v);
  }

  @override
  void initState() {
    super.initState();
    _lastDetent = _detentIndexFor(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: widget.value,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: widget.label,
      activeColor: widget.activeColor,
      onChanged: _onChanged,
    );
  }
}
