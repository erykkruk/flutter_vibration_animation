import 'package:flutter/material.dart';
import 'package:flutter_vibration_animation/flutter_vibration_animation.dart';

void main() => runApp(const VibrationDemoApp());

class VibrationDemoApp extends StatelessWidget {
  const VibrationDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibration & Haptics Demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const VibrationDemoPage(),
    );
  }
}

class VibrationDemoPage extends StatefulWidget {
  const VibrationDemoPage({super.key});

  @override
  State<VibrationDemoPage> createState() => _VibrationDemoPageState();
}

class _VibrationDemoPageState extends State<VibrationDemoPage> {
  HapticCapabilities? _capabilities;

  @override
  void initState() {
    super.initState();
    HapticCapabilities.query().then((c) => setState(() => _capabilities = c));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vibration & Haptics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_capabilities != null) _CapabilitiesCard(_capabilities!),
          const SizedBox(height: 16),
          _Section(
            title: 'Impact',
            children: [
              for (final style in HapticImpactStyle.values)
                FilledButton.tonal(
                  onPressed: () => Haptics.impact(style),
                  child: Text(style.name),
                ),
            ],
          ),
          _Section(
            title: 'Notification',
            children: [
              for (final style in HapticNotificationStyle.values)
                FilledButton.tonal(
                  onPressed: () => Haptics.notification(style),
                  child: Text(style.name),
                ),
            ],
          ),
          const _Section(
            title: 'Selection',
            children: [
              _SelectionButton(),
            ],
          ),
          _Section(
            title: 'Predefined',
            children: [
              for (final effect in PredefinedEffect.values)
                FilledButton.tonal(
                  onPressed: () => Vibration.playPredefined(effect),
                  child: Text(effect.name),
                ),
            ],
          ),
          _Section(
            title: 'Vibration',
            children: [
              FilledButton(
                onPressed: () => Vibration.vibrate(
                  duration: const Duration(milliseconds: 300),
                ),
                child: const Text('300ms'),
              ),
              FilledButton(
                onPressed: () => Vibration.vibrateWaveform(
                  timings: const [
                    Duration.zero,
                    Duration(milliseconds: 100),
                    Duration(milliseconds: 100),
                    Duration(milliseconds: 100),
                    Duration(milliseconds: 100),
                    Duration(milliseconds: 100),
                  ],
                  amplitudes: const [0, 80, 0, 160, 0, 255],
                ),
                child: const Text('rising waveform'),
              ),
              const _CancelButton(),
            ],
          ),
          _Section(
            title: 'Predefined patterns',
            children: [
              const _FixedActionButton(
                label: 'heartbeat',
                action: VibrationPatterns.heartbeat,
              ),
              const _FixedActionButton(
                label: 'notification',
                action: VibrationPatterns.notification,
              ),
              FilledButton(
                onPressed: () => VibrationPatterns.alarm(repeat: false),
                child: const Text('alarm'),
              ),
              const _FixedActionButton(
                label: 'success',
                action: VibrationPatterns.success,
              ),
              const _FixedActionButton(
                label: 'failure',
                action: VibrationPatterns.failure,
              ),
              const _FixedActionButton(
                label: 'charge up',
                action: VibrationPatterns.chargeUp,
              ),
            ],
          ),
          _Section(
            title: 'Custom Core Haptics pattern',
            children: [
              FilledButton(
                onPressed: () => HapticPattern.builder()
                    .tap(intensity: 0.4, sharpness: 0.6)
                    .pause(const Duration(milliseconds: 80))
                    .tap(intensity: 1.0, sharpness: 0.9)
                    .continuous(
                      duration: const Duration(milliseconds: 250),
                      intensity: 0.7,
                      sharpness: 0.3,
                    )
                    .play(),
                child: const Text('tap → tap → ramp'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton();

  @override
  Widget build(BuildContext context) => const FilledButton.tonal(
        onPressed: Haptics.selection,
        child: Text('selection'),
      );
}

class _CancelButton extends StatelessWidget {
  const _CancelButton();

  @override
  Widget build(BuildContext context) => const OutlinedButton(
        onPressed: Vibration.cancel,
        child: Text('cancel'),
      );
}

class _FixedActionButton extends StatelessWidget {
  const _FixedActionButton({required this.label, required this.action});
  final String label;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: action, child: Text(label));
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device capabilities',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _row('Vibrator', caps.hasVibrator),
            _row('Amplitude control', caps.hasAmplitudeControl),
            _row('Custom patterns', caps.supportsCustomPatterns),
            _row('Predefined effects', caps.supportsPredefinedEffects),
            _row('Impact feedback', caps.supportsImpactFeedback),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, bool value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: value ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      );
}
