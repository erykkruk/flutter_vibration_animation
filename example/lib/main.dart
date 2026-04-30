import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_vibration_animation/flutter_vibration_animation.dart';

void main() => runApp(const VibrationDemoApp());

class VibrationDemoApp extends StatelessWidget {
  const VibrationDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibration & Haptics Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const VibrationDemoPage(),
    );
  }
}

class VibrationDemoPage extends StatelessWidget {
  const VibrationDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_vibration_animation'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: const [
          _TypewriterDemo(),
          SizedBox(height: 32),
          _HeartbeatDemo(),
          SizedBox(height: 32),
          _LoadingRampDemo(),
          SizedBox(height: 32),
          _BouncyPressDemo(),
          SizedBox(height: 40),
          Divider(),
          SizedBox(height: 16),
          _RawApiSection(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 1 — Typewriter with per-character tick haptic
// ---------------------------------------------------------------------------

class _TypewriterDemo extends StatefulWidget {
  const _TypewriterDemo();

  @override
  State<_TypewriterDemo> createState() => _TypewriterDemoState();
}

class _TypewriterDemoState extends State<_TypewriterDemo> {
  static const String _phrase =
      'Each keystroke is a tiny haptic tick — feel it.';
  static const Duration _charDelay = Duration(milliseconds: 75);

  String _typed = '';
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _typed = '';
      _running = true;
    });
    var i = 0;
    _timer = Timer.periodic(_charDelay, (timer) {
      if (i >= _phrase.length) {
        timer.cancel();
        setState(() => _running = false);
        Haptics.notification(HapticNotificationStyle.success);
        return;
      }
      final char = _phrase[i];
      i++;
      setState(() => _typed += char);
      if (char != ' ') {
        Haptics.selection();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'Typewriter',
      subtitle: 'Selection haptic on every character',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 80),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            width: double.infinity,
            child: Text(
              _typed.isEmpty ? '_' : '$_typed${_running ? '|' : ''}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _running ? null : _start,
            icon: const Icon(Icons.keyboard),
            label: Text(_running ? 'Typing…' : 'Start typing'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 2 — Heartbeat with synced pulsing heart
// ---------------------------------------------------------------------------

class _HeartbeatDemo extends StatefulWidget {
  const _HeartbeatDemo();

  @override
  State<_HeartbeatDemo> createState() => _HeartbeatDemoState();
}

class _HeartbeatDemoState extends State<_HeartbeatDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // Two-pulse heartbeat — matches VibrationPatterns.heartbeat timings.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _beatOnce() async {
    setState(() => _running = true);
    await Future.wait([
      VibrationPatterns.heartbeat(),
      _controller.forward(from: 0),
    ]);
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'Heartbeat',
      subtitle: 'Vibration waveform synced with a pulsing heart',
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Center(
              child: ScaleTransition(
                scale: _scale,
                child: Icon(
                  Icons.favorite,
                  size: 96,
                  color: Colors.red.shade400,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _running ? null : _beatOnce,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Beat'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 3 — Loading bar 0→100% with haptic ramp light → medium → heavy
// ---------------------------------------------------------------------------

class _LoadingRampDemo extends StatefulWidget {
  const _LoadingRampDemo();

  @override
  State<_LoadingRampDemo> createState() => _LoadingRampDemoState();
}

class _LoadingRampDemoState extends State<_LoadingRampDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  // Threshold → haptic style. Crossing each threshold triggers exactly once.
  // Not const because Dart forbids `double` as a const map key.
  static final List<(double, HapticImpactStyle)> _ticks = [
    (0.25, HapticImpactStyle.light),
    (0.50, HapticImpactStyle.medium),
    (0.75, HapticImpactStyle.heavy),
  ];
  final Set<double> _fired = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..addListener(_onTick);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  void _onTick() {
    final value = _controller.value;
    for (final (threshold, style) in _ticks) {
      if (value >= threshold && _fired.add(threshold)) {
        Haptics.impact(style);
      }
    }
    if (value >= 1.0 && _fired.add(1.0)) {
      Haptics.notification(HapticNotificationStyle.success);
    }
  }

  Future<void> _start() async {
    _fired.clear();
    await _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'Loading ramp',
      subtitle: 'Ticks at 25 / 50 / 75% → success at 100%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final v = _controller.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 14,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(
                        Color.lerp(
                          Colors.lightBlueAccent,
                          Colors.deepOrangeAccent,
                          v,
                        )!,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(v * 100).round()}%',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _controller.isAnimating ? null : _start,
            icon: const Icon(Icons.refresh),
            label: const Text('Start loading'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo 4 — Bouncy press: scale-down on press, spring-bounce on release
// ---------------------------------------------------------------------------

class _BouncyPressDemo extends StatelessWidget {
  const _BouncyPressDemo();

  @override
  Widget build(BuildContext context) {
    return const _DemoCard(
      title: 'Bouncy press',
      subtitle: 'Tap & hold for impact + scale down, release for spring bounce',
      child: Center(child: _BouncyButton()),
    );
  }
}

class _BouncyButton extends StatefulWidget {
  const _BouncyButton();

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.86).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() {
    Haptics.impact(HapticImpactStyle.light);
    _controller.forward();
  }

  void _release() {
    Haptics.impact(HapticImpactStyle.medium);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: () {
        _controller.reverse();
      },
      onLongPress: () => Haptics.impact(HapticImpactStyle.heavy),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7C4DFF), Color(0xFFFF4081)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Press me',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Raw API section — direct access to every endpoint, no animation
// ---------------------------------------------------------------------------

class _RawApiSection extends StatefulWidget {
  const _RawApiSection();

  @override
  State<_RawApiSection> createState() => _RawApiSectionState();
}

class _RawApiSectionState extends State<_RawApiSection> {
  HapticCapabilities? _capabilities;

  @override
  void initState() {
    super.initState();
    HapticCapabilities.query().then(
      (c) => mounted ? setState(() => _capabilities = c) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Raw API', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_capabilities != null) _CapabilitiesCard(_capabilities!),
        const SizedBox(height: 16),
        _ChipRow(
          label: 'Impact',
          children: [
            for (final s in HapticImpactStyle.values)
              ActionChip(
                label: Text(s.name),
                onPressed: () => Haptics.impact(s),
              ),
          ],
        ),
        _ChipRow(
          label: 'Notification',
          children: [
            for (final s in HapticNotificationStyle.values)
              ActionChip(
                label: Text(s.name),
                onPressed: () => Haptics.notification(s),
              ),
          ],
        ),
        _ChipRow(
          label: 'Predefined',
          children: [
            for (final e in PredefinedEffect.values)
              ActionChip(
                label: Text(e.name),
                onPressed: () => Vibration.playPredefined(e),
              ),
          ],
        ),
        _ChipRow(
          label: 'Patterns',
          children: [
            ActionChip(
              label: const Text('alarm'),
              onPressed: () => VibrationPatterns.alarm(repeat: false),
            ),
            const ActionChip(
              label: Text('success'),
              onPressed: VibrationPatterns.success,
            ),
            const ActionChip(
              label: Text('failure'),
              onPressed: VibrationPatterns.failure,
            ),
            const ActionChip(
              label: Text('charge up'),
              onPressed: VibrationPatterns.chargeUp,
            ),
            const ActionChip(
              label: Text('cancel'),
              onPressed: Vibration.cancel,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _DemoCard extends StatelessWidget {
  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white60,
                  ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 4, children: children),
        ],
      ),
    );
  }
}

class _CapabilitiesCard extends StatelessWidget {
  const _CapabilitiesCard(this.caps);
  final HapticCapabilities caps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device capabilities',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          _row('Vibrator', caps.hasVibrator),
          _row('Amplitude control', caps.hasAmplitudeControl),
          _row('Custom patterns', caps.supportsCustomPatterns),
          _row('Predefined effects', caps.supportsPredefinedEffects),
          _row('Impact feedback', caps.supportsImpactFeedback),
        ],
      ),
    );
  }

  Widget _row(String label, bool value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: value ? Colors.greenAccent : Colors.white24,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      );
}
