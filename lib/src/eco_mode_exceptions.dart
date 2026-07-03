import 'package:flutter/services.dart';

/// An exception thrown by the flutter_eco_mode plugin.
///
/// Every error coming from the native side (iOS/Android) is surfaced as a
/// [PlatformException] with a specific `code`. This class (and its
/// subclasses) turn that generic, stringly-typed error into a well-defined,
/// catchable Dart type via [PlatformExceptionToEcoModeException].
sealed class EcoModeException implements Exception {
  /// The native error code this exception was mapped from (e.g.
  /// `STORAGE_ERROR`). Kept mainly for debugging/logging purposes; prefer
  /// matching on the concrete exception type rather than this code.
  final String code;

  /// A human-readable description of the error, if the native side
  /// provided one.
  final String? message;

  /// Extra, native-specific error details, if any.
  final Object? details;

  const EcoModeException({required this.code, this.message, this.details});

  @override
  String toString() => '$runtimeType($code, $message)';
}

/// Thrown when a native permission-related operation fails unexpectedly
/// (e.g. a `SecurityException` while reading network capabilities on
/// Android), independently of whether the permission was actually granted.
final class EcoModePermissionException extends EcoModeException {
  const EcoModePermissionException({super.message, super.details})
    : super(code: 'PERMISSION_ERROR');
}

/// Thrown when a required runtime permission has been denied by the user
/// or has not been requested yet.
final class EcoModePermissionDeniedException extends EcoModeException {
  const EcoModePermissionDeniedException({super.message, super.details})
    : super(code: 'PERMISSION_DENIED');
}

/// Thrown on Android when a permission request is made while the plugin is
/// not currently attached to an [Activity].
final class EcoModeActivityNotAttachedException extends EcoModeException {
  const EcoModeActivityNotAttachedException({super.message, super.details})
    : super(code: 'ACTIVITY_NOT_ATTACHED');
}

/// Thrown when the native platform fails to read storage information
/// (total/free disk space).
final class EcoModeStorageException extends EcoModeException {
  const EcoModeStorageException({super.message, super.details})
    : super(code: 'STORAGE_ERROR');
}

/// Thrown when an unknown/unmapped native error occurs.
final class EcoModeGenericException extends EcoModeException {
  const EcoModeGenericException({super.message, super.details})
    : super(code: 'GENERIC_ERROR');
}

extension PlatformExceptionToEcoModeException on PlatformException {
  /// Converts a [PlatformException] coming from the native platform into a
  /// typed [EcoModeException].
  EcoModeException toEcoModeException() {
    return switch (code) {
      'PERMISSION_ERROR' => EcoModePermissionException(
        message: message,
        details: details,
      ),
      'PERMISSION_DENIED' => EcoModePermissionDeniedException(
        message: message,
        details: details,
      ),
      'ACTIVITY_NOT_ATTACHED' => EcoModeActivityNotAttachedException(
        message: message,
        details: details,
      ),
      'STORAGE_ERROR' => EcoModeStorageException(
        message: message,
        details: details,
      ),
      _ => EcoModeGenericException(message: message, details: details),
    };
  }
}
