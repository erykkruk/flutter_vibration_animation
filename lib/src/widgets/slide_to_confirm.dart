import 'package:flutter/material.dart';

import '../haptic_feedback.dart';

/// Pill-shaped track with a draggable handle. The user must drag the
/// handle from left edge to right edge to confirm.
///
/// While dragging, light haptic ticks fire at 25%, 50% and 75% progress.
/// Reaching 100% fires a heavy impact + [onConfirmed] and the handle
/// stays at the end. Releasing before 100% springs the handle back to
/// the start with a light tick.
///
/// Iconic pattern in payment / driver / "are you sure" flows (Uber's
/// "Slide to start", Cash App "Slide to pay", etc).
///
/// ```dart
/// SlideToConfirm(
///   label: 'Slide to pay',
///   onConfirmed: () => pay(),
/// )
/// ```
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.onConfirmed,
    this.label = 'Slide to confirm',
    this.height = 64,
    this.handleIcon = Icons.arrow_forward,
    this.confirmedIcon = Icons.check,
    this.trackColor,
    this.handleColor,
    this.textColor,
  });

  final VoidCallback onConfirmed;
  final String label;
  final double height;
  final IconData handleIcon;
  final IconData confirmedIcon;
  final Color? trackColor;
  final Color? handleColor;
  final Color? textColor;

  @override
  State<SlideToConfirm> createState() => SlideToConfirmState();
}

/// State exposed so callers can call [reset] via a `GlobalKey`.
class SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  static const List<double> _tickThresholds = [0.25, 0.50, 0.75];

  late final AnimationController _controller; // 0..1 = handle position
  bool _dragging = false;
  bool _confirmed = false;
  final Set<double> _firedTicks = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addListener(_onProgressTick);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onProgressTick)
      ..dispose();
    super.dispose();
  }

  /// Re-arms the widget after a successful confirmation. Has no effect
  /// while a drag is in progress or the user has not yet confirmed.
  void reset() {
    if (_dragging) return;
    setState(() {
      _confirmed = false;
      _firedTicks.clear();
      _controller.value = 0;
    });
  }

  void _onProgressTick() {
    final v = _controller.value;
    for (final t in _tickThresholds) {
      if (v >= t && _firedTicks.add(t)) {
        Haptics.impact(HapticImpactStyle.light);
      }
    }
  }

  void _onDragStart(double trackWidth) {
    if (_confirmed) return;
    _dragging = true;
    _firedTicks.clear();
  }

  void _onDragUpdate(double dx, double trackWidth) {
    if (_confirmed || !_dragging) return;
    final next = (_controller.value + dx / trackWidth).clamp(0.0, 1.0);
    _controller.value = next;
  }

  void _onDragEnd(double trackWidth) {
    _dragging = false;
    if (_controller.value >= 0.98) {
      _controller.value = 1.0;
      _confirmed = true;
      Haptics.impact(HapticImpactStyle.heavy);
      widget.onConfirmed();
      setState(() {});
    } else {
      Haptics.impact(HapticImpactStyle.light);
      _controller.animateBack(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
      );
      _firedTicks.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track =
        widget.trackColor ?? theme.colorScheme.primary.withValues(alpha: 0.2);
    final handle = widget.handleColor ?? theme.colorScheme.primary;
    final text = widget.textColor ?? theme.colorScheme.onSurface;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final handleSize = widget.height - 8;
        final travel = width - handleSize - 8;

        return SizedBox(
          height: widget.height,
          child: Stack(
            children: [
              Container(
                width: width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: track,
                  borderRadius: BorderRadius.circular(widget.height),
                ),
                alignment: Alignment.center,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Opacity(
                    opacity: (1 - _controller.value).clamp(0.0, 1.0),
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: text,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Positioned(
                  left: 4 + travel * _controller.value,
                  top: 4,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) => _onDragStart(travel),
                    onHorizontalDragUpdate: (d) =>
                        _onDragUpdate(d.delta.dx, travel),
                    onHorizontalDragEnd: (_) => _onDragEnd(travel),
                    onHorizontalDragCancel: () => _onDragEnd(travel),
                    child: Container(
                      width: handleSize,
                      height: handleSize,
                      decoration: BoxDecoration(
                        color: handle,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: handle.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _confirmed ? widget.confirmedIcon : widget.handleIcon,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
