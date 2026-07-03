import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/src/messages.g.dart';

class MockEcoModeApi extends Mock implements EcoModeApi {}

void main() {
  late StreamController<Connectivity> connectivityStreamController;
  late EcoModeApi ecoModeApi;

  FlutterEcoMode buildEcoMode() => FlutterEcoMode(
    api: ecoModeApi,
    connectivityStream: connectivityStreamController.stream,
  );

  setUp(() {
    ecoModeApi = MockEcoModeApi();
    connectivityStreamController = StreamController<Connectivity>.broadcast();
  });

  tearDown(() {
    connectivityStreamController.close();
  });

  group('_guard error conversion', () {
    test(
      'converts a PLATFORM_ERROR PlatformException into EcoModeGenericException',
      () async {
        when(() => ecoModeApi.getPlatformInfo()).thenThrow(
          PlatformException(code: 'SOME_UNMAPPED_CODE', message: 'boom'),
        );

        await expectLater(
          buildEcoMode().getPlatformInfo(),
          throwsA(
            isA<EcoModeGenericException>()
                .having((e) => e.code, 'code', 'GENERIC_ERROR')
                .having((e) => e.message, 'message', 'boom'),
          ),
        );
      },
    );

    test(
      'converts a STORAGE_ERROR PlatformException into EcoModeStorageException',
      () async {
        when(() => ecoModeApi.getTotalStorage()).thenThrow(
          PlatformException(code: 'STORAGE_ERROR', message: 'disk failure'),
        );

        await expectLater(
          buildEcoMode().getTotalStorage(),
          throwsA(
            isA<EcoModeStorageException>()
                .having((e) => e.code, 'code', 'STORAGE_ERROR')
                .having((e) => e.message, 'message', 'disk failure'),
          ),
        );
      },
    );

    test(
      'converts a PERMISSION_ERROR PlatformException into EcoModePermissionException',
      () async {
        when(() => ecoModeApi.getConnectivity()).thenThrow(
          PlatformException(code: 'PERMISSION_ERROR', message: 'no access'),
        );

        await expectLater(
          buildEcoMode().getConnectivity(),
          throwsA(
            isA<EcoModePermissionException>()
                .having((e) => e.code, 'code', 'PERMISSION_ERROR')
                .having((e) => e.message, 'message', 'no access'),
          ),
        );
      },
    );

    test(
      'converts a PERMISSION_DENIED PlatformException into EcoModePermissionDeniedException',
      () async {
        when(() => ecoModeApi.getConnectivity()).thenThrow(
          PlatformException(code: 'PERMISSION_DENIED', message: 'denied'),
        );

        await expectLater(
          buildEcoMode().getConnectivity(),
          throwsA(
            isA<EcoModePermissionDeniedException>().having(
              (e) => e.code,
              'code',
              'PERMISSION_DENIED',
            ),
          ),
        );
      },
    );

    test(
      'converts an ACTIVITY_NOT_ATTACHED PlatformException into EcoModeActivityNotAttachedException',
      () async {
        when(() => ecoModeApi.getConnectivity()).thenThrow(
          PlatformException(
            code: 'ACTIVITY_NOT_ATTACHED',
            message: 'no activity',
          ),
        );

        await expectLater(
          buildEcoMode().getConnectivity(),
          throwsA(
            isA<EcoModeActivityNotAttachedException>().having(
              (e) => e.code,
              'code',
              'ACTIVITY_NOT_ATTACHED',
            ),
          ),
        );
      },
    );

    test('does not wrap errors that are not PlatformException', () async {
      when(
        () => ecoModeApi.getBatteryLevel(),
      ).thenThrow(StateError('unexpected'));

      await expectLater(
        buildEcoMode().getBatteryLevel(),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'hasEnoughNetwork returns null instead of throwing when getConnectivity fails',
      () async {
        when(() => ecoModeApi.getConnectivity()).thenThrow(
          PlatformException(code: 'PERMISSION_DENIED', message: 'denied'),
        );

        expect(await buildEcoMode().hasEnoughNetwork(), isNull);
      },
    );
  });
}
