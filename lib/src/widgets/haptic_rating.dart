import 'dart:async';

import 'package:flutter/material.dart';

import '../haptic_feedback.dart';

/// Star rating row that fills with a cascading animation when the user
/// taps a star. Each star fill triggers a haptic tick, so the user feels
/// every star light up in sequence.
///
/// ```dart
/// HapticRating(
///   value: _rating,
///   starCount: 5,
///   onChanged: (v) => setState(() => _rating = v),
/// )
/// ```
class HapticRating extends StatefulWidget {
  const HapticRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.starCount = 5,
    this.size = 36,
    this.spacing = 6,
    this.activeColor = Colors.amber,
    this.inactiveColor = const Color(0xFF3A3A3C),
    this.cascadeDelay = const Duration(milliseconds: 65),
  }) : assert(
          starCount > 0,
          'starCount must be > 0',
        );

  /// Current rating, in `0..starCount`.
  final int value;
  final ValueChanged<int> onChanged;
  final int starCount;
  final double size;
  final double spacing;
  final Color activeColor;
  final Color inactiveColor;

  /// Time between each star "lighting up" during the cascade.
  final Duration cascadeDelay;

  @override
  State<HapticRating> createState() => _HapticRatingState();
}

class _HapticRatingState extends State<HapticRating> {
  late int _displayValue;
  Timer? _cascade;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
  }

  @override
  void didUpdateWidget(HapticRating oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _displayValue = widget.value;
    }
  }

  @override
  void dispose() {
    _cascade?.cancel();
    super.dispose();
  }

  void _onTap(int index) {
    final target = index + 1;
    widget.onChanged(target);
    _cascade?.cancel();

    // Start from 0 so every star (including the tapped one) re-fills with
    // a tick. Capped sequence — never schedules more ticks than there are
    // stars to light up.
    setState(() => _displayValue = 0);
    var i = 0;
    _cascade = Timer.periodic(widget.cascadeDelay, (timer) {
      if (i >= target) {
        timer.cancel();
        return;
      }
      i++;
      setState(() => _displayValue = i);
      Haptics.selection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.starCount; i++)
          Padding(
            padding: EdgeInsets.only(
              right: i == widget.starCount - 1 ? 0 : widget.spacing,
            ),
            child: GestureDetector(
              onTap: () => _onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedScale(
                scale: i < _displayValue ? 1.0 : 0.85,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutBack,
                child: Icon(
                  i < _displayValue ? Icons.star_rounded : Icons.star_outline,
                  size: widget.size,
                  color: i < _displayValue
                      ? widget.activeColor
                      : widget.inactiveColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
