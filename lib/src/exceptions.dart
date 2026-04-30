/// Base class for all errors thrown by `flutter_vibration_animation`.
sealed class VibrationException implements Exception {
  const VibrationException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when the requested capability is not supported by the device
/// (e.g. Core Haptics on a device without the Taptic Engine, or amplitude
/// control on an older Android phone).
class UnsupportedHapticException extends VibrationException {
  const UnsupportedHapticException(super.message);
}

/// Thrown when a parameter passed to the public API is out of range or
/// otherwise invalid.
class InvalidVibrationArgumentException extends VibrationException {
  const InvalidVibrationArgumentException(super.message);
}

/// Thrown when the underlying platform call fails (native exception, missing
/// plugin, channel error).
class PlatformVibrationException extends VibrationException {
  const PlatformVibrationException(super.message, {this.code});

  final String? code;
}
