import 'exceptions.dart';
import 'method_channel.dart';

/// A single event in a [HapticPattern].
///
/// On iOS this maps to a `CHHapticEvent` (`hapticTransient` for instantaneous
/// taps, `hapticContinuous` for events with non-zero [duration]). On Android
/// the event is rendered as a segment of a `VibrationEffect.createWaveform`,
/// where [intensity] is mapped to amplitude.
class HapticEvent {
  const HapticEvent({
    required this.intensity,
    required this.sharpness,
    this.duration = Duration.zero,
    this.relativeTime = Duration.zero,
  })  : assert(
          intensity >= 0.0 && intensity <= 1.0,
          'intensity must be in [0, 1]',
        ),
        assert(
          sharpness >= 0.0 && sharpness <= 1.0,
          'sharpness must be in [0, 1]',
        );

  /// `0.0`–`1.0` — overall strength of the event.
  final double intensity;

  /// `0.0`–`1.0` — perceptual "sharpness" of the event (iOS only; ignored on
  /// Android, which has no equivalent).
  final double sharpness;

  /// If non-zero, the event is continuous and lasts for [duration]. Otherwise
  /// it is treated as a single tap.
  final Duration duration;

  /// Offset from pattern start at which this event begins.
  final Duration relativeTime;

  Map<String, dynamic> toMap() => {
        'intensity': intensity,
        'sharpness': sharpness,
        'durationMs': duration.inMilliseconds,
        'relativeTimeMs': relativeTime.inMilliseconds,
      };
}

/// Fluent builder for custom haptic sequences.
///
/// ```dart
/// await HapticPattern.builder()
///     .tap(intensity: 0.4, sharpness: 0.6)
///     .pause(const Duration(milliseconds: 80))
///     .tap(intensity: 1.0, sharpness: 0.9)
///     .continuous(
///       duration: const Duration(milliseconds: 250),
///       intensity: 0.7,
///       sharpness: 0.3,
///     )
///     .play();
/// ```
class HapticPattern {
  HapticPattern._();

  /// Start building a new pattern.
  factory HapticPattern.builder() = HapticPattern._;

  final List<HapticEvent> _events = [];
  Duration _cursor = Duration.zero;

  /// Add a single tap event.
  HapticPattern tap({
    required double intensity,
    required double sharpness,
  }) {
    _events.add(
      HapticEvent(
        intensity: intensity,
        sharpness: sharpness,
        relativeTime: _cursor,
      ),
    );
    return this;
  }

  /// Add a continuous event lasting [duration].
  HapticPattern continuous({
    required Duration duration,
    required double intensity,
    required double sharpness,
  }) {
    if (duration.inMilliseconds <= 0) {
      throw const InvalidVibrationArgumentException(
        'continuous duration must be > 0 ms',
      );
    }
    _events.add(
      HapticEvent(
        intensity: intensity,
        sharpness: sharpness,
        duration: duration,
        relativeTime: _cursor,
      ),
    );
    _cursor += duration;
    return this;
  }

  /// Insert a silent gap between events.
  HapticPattern pause(Duration duration) {
    if (duration.inMilliseconds <= 0) {
      throw const InvalidVibrationArgumentException(
        'pause duration must be > 0 ms',
      );
    }
    _cursor += duration;
    return this;
  }

  /// Append a raw [HapticEvent]. The event's [HapticEvent.relativeTime] is
  /// used as-is — it is the caller's responsibility to keep events ordered.
  HapticPattern addEvent(HapticEvent event) {
    _events.add(event);
    return this;
  }

  /// Number of events queued so far.
  int get length => _events.length;

  /// Snapshot of the current event list.
  List<HapticEvent> get events => List.unmodifiable(_events);

  /// Send the pattern to the native side and play it.
  ///
  /// Throws [UnsupportedHapticException] when the device has no Core Haptics
  /// support (older iPhones) and no waveform-amplitude vibrator (older
  /// Android), in which case the caller should fall back to `Haptics`.
  Future<void> play() {
    if (_events.isEmpty) {
      throw const InvalidVibrationArgumentException(
        'pattern has no events — add at least one tap or continuous event',
      );
    }
    return HapticKitChannel.invoke<void>('pattern.play', {
      'events': _events.map((e) => e.toMap()).toList(),
    });
  }
}
