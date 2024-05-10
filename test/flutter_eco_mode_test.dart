import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/flutter_eco_mode_platform_interface.dart';
import 'package:flutter_eco_mode/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

import 'flutter_eco_mode_fixtures.dart';

void main() {
  group(
    'isBatteryEcoMode',
    () {
      test('should return false', () async {
        final ecoMode = FlutterEcoModeTest();
        expect(await ecoMode.isBatteryEcoMode(), false);
      });

      test('should return true when not enough battery and discharging',
          () async {
        final fakePlatform = FlutterEcoModeTest(
          batteryLevel: minEnoughBattery - 1,
          batteryState: BatteryState.discharging,
        );
        expect(await fakePlatform.isBatteryEcoMode(), true);
      });

      test('should return true when battery in low power mode', () async {
        final fakePlatform = FlutterEcoModeTest(
          isBatteryLowPowerMode: true,
        );
        expect(await fakePlatform.isBatteryEcoMode(), true);
      });

      test('should return true when thermal state is critical', () async {
        final fakePlatform = FlutterEcoModeTest(
          thermalState: ThermalState.critical,
        );
        expect(await fakePlatform.isBatteryEcoMode(), true);
      });

      test('should return true when thermal state is serious', () async {
        final fakePlatform = FlutterEcoModeTest(
          thermalState: ThermalState.serious,
        );
        expect(await fakePlatform.isBatteryEcoMode(), true);
      });

      test('should return null when thermal state is serious', () async {
        final fakePlatform = FlutterEcoModeTest(
          thermalState: ThermalState.serious,
        );
        expect(await fakePlatform.isBatteryEcoMode(), true);
      });

      test(
          'should return true when thermal state is serious and battery level is in error',
          () async {
        final fakePlatform = FlutterEcoModeTest(
          thermalState: ThermalState.serious,
          getBatteryLevelFuture: () => Future.error('error battery level'),
        );
        expect(await fakePlatform.isBatteryEcoMode(), true);
      });

      test(
          'should return false when thermal state is safe and battery level is in error',
          () async {
        final fakePlatform = FlutterEcoModeTest(
          thermalState: ThermalState.safe,
          getBatteryLevelFuture: () => Future.error('error battery level'),
        );
        expect(await fakePlatform.isBatteryEcoMode(), false);
      });

      test('should return null when impossible to get battery info', () async {
        final fakePlatform = FlutterEcoModeTest(
          getThermalStateFuture: () => Future.error('error thermal state'),
          getBatteryLevelFuture: () => Future.error('error battery level'),
          isBatteryInLowPowerModeFuture: () =>
              Future.error('error battery low power mode'),
          getBatteryStateFuture: () => Future.error('error battery state'),
        );
        expect(await fakePlatform.isBatteryEcoMode(), null);
      });

      test('should wait all the future to complete the statement', () async {
        final fakePlatform = FlutterEcoModeTest(
          batteryLevelMsDelay: 100,
          isBatteryInLowPowerModeMsDelay: 200,
          thermalStateMsDelay: 300,
          thermalState: ThermalState.serious,
        );
        expect(await fakePlatform.isBatteryEcoMode(), true);
      });
    },
  );

  group(
    'getEcoRange',
    () {
      test('should return null when get eco score error', () async {
        final ecoMode = FlutterEcoMode(
          api: EcoModeApiTest(
            getEcoScoreFuture: () => Future.error('error eco score'),
          ),
        );
        expect(await ecoMode.getEcoRange(), null);
      });

      test('should return null when get eco score null', () async {
        final ecoMode = FlutterEcoMode(
          api: EcoModeApiTest(
            getEcoScoreFuture: () => Future.value(null),
          ),
        );
        expect(await ecoMode.getEcoRange(), null);
      });

      test('should return low end device', () async {
        final ecoMode = FlutterEcoMode(
          api: EcoModeApiTest(
            getEcoScoreFuture: () => Future.value(minScoreLowEndDevice),
          ),
        );
        final ecoRange = await ecoMode.getEcoRange();
        expect(ecoRange!.score, minScoreLowEndDevice);
        expect(ecoRange.range, DeviceEcoRange.lowEnd);
        expect(ecoRange.isLowEndDevice, true);
      });

      test('should return mid range device', () async {
        final ecoMode = FlutterEcoMode(
          api: EcoModeApiTest(
            getEcoScoreFuture: () => Future.value(minScoreMidRangeDevice),
          ),
        );
        final ecoRange = await ecoMode.getEcoRange();
        expect(ecoRange!.score, minScoreMidRangeDevice);
        expect(ecoRange.range, DeviceEcoRange.midRange);
        expect(ecoRange.isLowEndDevice, false);
      });

      test('should return high end device', () async {
        final ecoMode = FlutterEcoMode(
          api: EcoModeApiTest(
            getEcoScoreFuture: () => Future.value(minScoreMidRangeDevice + 0.1),
          ),
        );
        final ecoRange = await ecoMode.getEcoRange();
        expect(ecoRange!.score, minScoreMidRangeDevice + 0.1);
        expect(ecoRange.range, DeviceEcoRange.highEnd);
        expect(ecoRange.isLowEndDevice, false);
      });
    },
  );
}
