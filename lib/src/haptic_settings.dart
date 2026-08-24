import 'haptic_capabilities.dart';

/// App-wide switch and capability cache for every haptic in this package.
///
/// Almost every app that ships haptics also ships a "Haptics" toggle in its
/// settings, and every such app ends up wrapping each call in the same
/// `if (settings.hapticsOn)`. Flip it once here instead:
///
/// ```dart
/// HapticSettings.enabled = preferences.hapticsEnabled;
///
/// // Now a no-op, from anywhere, without a check at the call site
/// await Haptics.impact(HapticImpactStyle.light);
/// ```
///
/// While disabled, calls return normally and do nothing: the native side is
/// never reached, so a disabled app makes no platform calls at all rather
/// than making them and discarding the result.
///
/// This is the app's own preference. It does not read the system-level
/// haptic setting, which the platforms apply themselves underneath.
abstract final class HapticSettings {
  /// Whether haptics and vibration are allowed to play. Defaults to true.
  ///
  /// Setting it to false turns every [Haptics], [Vibration],
  /// [VibrationPatterns] and haptic widget call in the package into a
  /// no-op, including any already-running pattern's remaining steps.
  static bool enabled = true;

  static HapticCapabilities? _capabilities;

  /// The device's capabilities, queried once and cached.
  ///
  /// The values cannot change while the app runs, so repeated reads cost
  /// nothing after the first. The underlying `HapticCapabilities.query()`
  /// stays available for a deliberately fresh read.
  ///
  /// A failed query is not cached, so a transient platform error does not
  /// pin an "unsupported" answer for the rest of the session.
  static Future<HapticCapabilities> get capabilities async {
    final cached = _capabilities;
    if (cached != null) return cached;
    final queried = await HapticCapabilities.query();
    _capabilities = queried;
    return queried;
  }

  /// The cached capabilities, or null if they have not been read yet.
  ///
  /// Useful for a synchronous check on a UI build after an earlier await.
  static HapticCapabilities? get cachedCapabilities => _capabilities;

  /// Drops the cached capabilities so the next read queries the platform.
  ///
  /// Mainly for tests; device capabilities do not change at runtime.
  static void resetCapabilitiesCache() => _capabilities = null;

  /// Whether this device can play anything at all.
  ///
  /// Shorthand for `(await capabilities).hasVibrator`, and false whenever
  /// [enabled] is false, so one check covers both the device and the user's
  /// preference.
  static Future<bool> get isAvailable async {
    if (!enabled) return false;
    return (await capabilities).hasVibrator;
  }
}
