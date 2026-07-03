import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_eco_mode/src/eco_mode_exceptions.dart';

void main() {
  group('EcoModeException subclasses', () {
    test('EcoModePermissionException has the expected code', () {
      final exception = EcoModePermissionException(message: 'permission error');

      expect(exception.code, 'PERMISSION_ERROR');
      expect(exception.message, 'permission error');
      expect(exception.details, isNull);
      expect(exception, isA<EcoModeException>());
    });

    test('EcoModePermissionDeniedException has the expected code', () {
      final exception = EcoModePermissionDeniedException(
        message: 'permission denied',
        details: {'reason': 'denied'},
      );

      expect(exception.code, 'PERMISSION_DENIED');
      expect(exception.message, 'permission denied');
      expect(exception.details, {'reason': 'denied'});
      expect(exception, isA<EcoModeException>());
    });

    test('EcoModeActivityNotAttachedException has the expected code', () {
      final exception = EcoModeActivityNotAttachedException(
        message: 'activity not attached',
      );

      expect(exception.code, 'ACTIVITY_NOT_ATTACHED');
      expect(exception.message, 'activity not attached');
      expect(exception, isA<EcoModeException>());
    });

    test('EcoModeStorageException has the expected code', () {
      final exception = EcoModeStorageException(message: 'storage error');

      expect(exception.code, 'STORAGE_ERROR');
      expect(exception.message, 'storage error');
      expect(exception, isA<EcoModeException>());
    });

    test('EcoModeGenericException has the expected code', () {
      final exception = EcoModeGenericException(message: 'unknown error');

      expect(exception.code, 'GENERIC_ERROR');
      expect(exception.message, 'unknown error');
      expect(exception, isA<EcoModeException>());
    });

    test('toString returns the expected format', () {
      final exception = EcoModeStorageException(
        message: 'storage error',
        details: {'path': '/data'},
      );

      expect(
        exception.toString(),
        'EcoModeException(STORAGE_ERROR, storage error, {path: /data})',
      );
    });
  });

  group('PlatformExceptionToEcoModeException', () {
    test('maps PERMISSION_ERROR to EcoModePermissionException', () {
      final platformException = PlatformException(
        code: 'PERMISSION_ERROR',
        message: 'permission error',
        details: {'foo': 'bar'},
      );

      final result = platformException.toEcoModeException();

      expect(result, isA<EcoModePermissionException>());
      expect(result.code, 'PERMISSION_ERROR');
      expect(result.message, 'permission error');
      expect(result.details, {'foo': 'bar'});
    });

    test('maps PERMISSION_DENIED to EcoModePermissionDeniedException', () {
      final platformException = PlatformException(
        code: 'PERMISSION_DENIED',
        message: 'permission denied',
      );

      final result = platformException.toEcoModeException();

      expect(result, isA<EcoModePermissionDeniedException>());
      expect(result.code, 'PERMISSION_DENIED');
      expect(result.message, 'permission denied');
    });

    test(
      'maps ACTIVITY_NOT_ATTACHED to EcoModeActivityNotAttachedException',
      () {
        final platformException = PlatformException(
          code: 'ACTIVITY_NOT_ATTACHED',
          message: 'activity not attached',
        );

        final result = platformException.toEcoModeException();

        expect(result, isA<EcoModeActivityNotAttachedException>());
        expect(result.code, 'ACTIVITY_NOT_ATTACHED');
        expect(result.message, 'activity not attached');
      },
    );

    test('maps STORAGE_ERROR to EcoModeStorageException', () {
      final platformException = PlatformException(
        code: 'STORAGE_ERROR',
        message: 'storage error',
      );

      final result = platformException.toEcoModeException();

      expect(result, isA<EcoModeStorageException>());
      expect(result.code, 'STORAGE_ERROR');
      expect(result.message, 'storage error');
    });

    test('maps unknown codes to EcoModeGenericException', () {
      final platformException = PlatformException(
        code: 'SOME_UNMAPPED_CODE',
        message: 'unmapped error',
      );

      final result = platformException.toEcoModeException();

      expect(result, isA<EcoModeGenericException>());
      expect(result.code, 'GENERIC_ERROR');
      expect(result.message, 'unmapped error');
    });

    test('preserves details when mapping to EcoModeGenericException', () {
      final platformException = PlatformException(
        code: 'SOME_UNMAPPED_CODE',
        message: 'unmapped error',
        details: {'extra': 'info'},
      );

      final result = platformException.toEcoModeException();

      expect(result.details, {'extra': 'info'});
    });
  });
}
