import 'package:flutter/services.dart';

import 'exceptions.dart';
import 'haptic_settings.dart';

/// Internal: shared [MethodChannel] for all calls to the native side.
///
/// Not exported from the package barrel — consumer code should use
/// [Haptics], [Vibration], [HapticPattern] etc. instead.
class HapticKitChannel {
  HapticKitChannel._();

  static const String channelName = 'dev.erykkruk/haptic_kit';
  static const MethodChannel _channel = MethodChannel(channelName);

  /// Invoke a method on the native plugin and translate any platform error
  /// into a typed [PlatformVibrationException].
  ///
  /// [playback] marks calls that actually make the device buzz. Those are
  /// skipped entirely while [HapticSettings.enabled] is false, so a user who
  /// turned haptics off costs no platform calls at all. Queries and
  /// cancellation pass through either way: reading what the device supports,
  /// or stopping something already running, is not playback.
  static Future<T?> invoke<T>(
    String method, [
    Map<String, dynamic>? arguments,
    bool playback = true,
  ]) async {
    if (playback && !HapticSettings.enabled) {
      return null;
    }
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      if (e.code == 'unsupported') {
        throw UnsupportedHapticException(e.message ?? 'Capability unsupported');
      }
      if (e.code == 'invalid_argument') {
        throw InvalidVibrationArgumentException(
          e.message ?? 'Invalid argument',
        );
      }
      throw PlatformVibrationException(
        e.message ?? 'Native call failed',
        code: e.code,
      );
    } on MissingPluginException {
      throw const PlatformVibrationException(
        'Plugin not registered on this platform',
        code: 'missing_plugin',
      );
    }
  }

  /// Visible for testing only — allows swapping the channel handler in tests.
  // ignore: invalid_use_of_visible_for_testing_member
  static MethodChannel get debugChannel => _channel;
}
