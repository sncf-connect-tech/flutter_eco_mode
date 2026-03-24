import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/src/constants.dart';
import 'package:flutter_eco_mode/src/messages.g.dart';

class MockEcoModeApi extends Mock implements EcoModeApi {}

void main() {
  late StreamController<double> batteryLevelStreamController;
  late StreamController<BatteryState> batteryStateStreamController;
  late StreamController<bool> batteryModeStreamController;
  late StreamController<Connectivity> connectivityStreamController;
  late EcoModeApi ecoModeApi;

  FlutterEcoMode buildEcoMode() => FlutterEcoMode(
    api: ecoModeApi,
    batteryLevelStream: batteryLevelStreamController.stream,
    batteryStateStream: batteryStateStreamController.stream,
    batteryModeStream: batteryModeStreamController.stream,
    connectivityStream: connectivityStreamController.stream,
  );

  setUp(() {
    ecoModeApi = MockEcoModeApi();
    when(
      () => ecoModeApi.isBatteryInLowPowerMode(),
    ).thenAnswer((_) async => false);
    when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 100.0);
    when(
      () => ecoModeApi.getBatteryState(),
    ).thenAnswer((_) async => BatteryState.charging);
    when(
      () => ecoModeApi.getThermalState(),
    ).thenAnswer((_) async => ThermalState.safe);
    batteryLevelStreamController = StreamController<double>.broadcast();
    batteryStateStreamController = StreamController<BatteryState>.broadcast();
    batteryModeStreamController = StreamController<bool>.broadcast();
    connectivityStreamController = StreamController<Connectivity>.broadcast();
  });

  tearDown(() {
    batteryLevelStreamController.close();
    batteryStateStreamController.close();
    batteryModeStreamController.close();
    connectivityStreamController.close();
  });

  group('Edge Cases Tests', () {
    group('Boundary value handling', () {
      test('should handle battery level 0%', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 0.0);
        expect(await buildEcoMode().getBatteryLevel(), 0.0);
      });

      test('should handle battery level 100%', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 100.0);
        expect(await buildEcoMode().getBatteryLevel(), 100.0);
      });

      test('should handle very small battery level', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 0.001);
        expect(await buildEcoMode().getBatteryLevel(), 0.001);
      });

      test('should handle very large memory values', () async {
        const largeValue = 999999999999;
        when(
          () => ecoModeApi.getTotalMemory(),
        ).thenAnswer((_) async => largeValue);
        expect(await buildEcoMode().getTotalMemory(), largeValue);
      });

      test('should handle zero free memory', () async {
        when(() => ecoModeApi.getFreeMemory()).thenAnswer((_) async => 0);
        expect(await buildEcoMode().getFreeMemory(), 0);
      });

      test('should handle zero processor count', () async {
        when(() => ecoModeApi.getProcessorCount()).thenAnswer((_) async => 0);
        expect(await buildEcoMode().getProcessorCount(), 0);
      });

      test('should handle extreme processor count', () async {
        when(() => ecoModeApi.getProcessorCount()).thenAnswer((_) async => 256);
        expect(await buildEcoMode().getProcessorCount(), 256);
      });

      test('should handle zero storage', () async {
        when(() => ecoModeApi.getTotalStorage()).thenAnswer((_) async => 0);
        when(() => ecoModeApi.getFreeStorage()).thenAnswer((_) async => 0);
        final ecoMode = buildEcoMode();
        expect(await ecoMode.getTotalStorage(), 0);
        expect(await ecoMode.getFreeStorage(), 0);
      });
    });

    group('Extreme and overshoot values', () {
      test('should handle battery level above 100', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 105.0);
        expect(await buildEcoMode().getBatteryLevel(), 105.0);
      });

      test('should handle very large storage values', () async {
        const hugeStorage = 9999999999999;
        when(
          () => ecoModeApi.getTotalStorage(),
        ).thenAnswer((_) async => hugeStorage);
        expect(await buildEcoMode().getTotalStorage(), hugeStorage);
      });

      test('should handle eco score at boundaries', () async {
        when(
          () => ecoModeApi.getEcoScore(),
        ).thenAnswer((_) async => minScoreLowEndDevice - 0.1);
        final deviceRange = await buildEcoMode().getDeviceRange();
        expect(deviceRange, isNotNull);
        expect(deviceRange.score, minScoreLowEndDevice - 0.1);
      });

      test('should handle eco score at mid-point', () async {
        when(
          () => ecoModeApi.getEcoScore(),
        ).thenAnswer((_) async => minScoreMidRangeDevice);
        final deviceRange = await buildEcoMode().getDeviceRange();
        expect(deviceRange, isNotNull);
        expect(deviceRange.range, DeviceEcoRange.midRange);
      });

      test('should handle max eco score', () async {
        when(() => ecoModeApi.getEcoScore()).thenAnswer((_) async => 1.0);
        final deviceRange = await buildEcoMode().getDeviceRange();
        expect(deviceRange, isNotNull);
        expect(deviceRange.range, DeviceEcoRange.highEnd);
      });
    });

    group('Rapid sequential operations', () {
      test('should handle rapid concurrent getter calls', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 75.0);
        when(
          () => ecoModeApi.getTotalMemory(),
        ).thenAnswer((_) async => 8000000000);
        when(
          () => ecoModeApi.getFreeMemory(),
        ).thenAnswer((_) async => 2000000000);

        final ecoMode = buildEcoMode();
        final futures = <Future<dynamic>>[];

        for (int i = 0; i < 50; i++) {
          futures.add(ecoMode.getBatteryLevel());
          futures.add(ecoMode.getTotalMemory());
          futures.add(ecoMode.getFreeMemory());
        }

        final results = await Future.wait(futures);
        expect(results.length, 150);
      });

      test('should handle rapid stream emissions', () async {
        final ecoMode = buildEcoMode();
        final results = <double>[];

        ecoMode.batteryLevelEventStream.listen((value) {
          results.add(value);
        });

        // Emit 500 values rapidly
        for (int i = 0; i < 500; i++) {
          batteryLevelStreamController.add(i.toDouble());
        }

        await Future.delayed(const Duration(milliseconds: 300));

        expect(results.length, 500);
      });

      test('should handle interleaved stream emissions', () async {
        final ecoMode = buildEcoMode();
        final allEvents = <String>[];

        ecoMode.batteryLevelEventStream.listen((value) {
          allEvents.add('battery');
        });
        ecoMode.batteryStateEventStream.listen((value) {
          allEvents.add('state');
        });
        ecoMode.lowPowerModeEventStream.listen((value) {
          allEvents.add('mode');
        });

        // Interleave emissions
        for (int i = 0; i < 10; i++) {
          batteryLevelStreamController.add(i.toDouble());
          batteryStateStreamController.add(
            i.isEven ? BatteryState.charging : BatteryState.discharging,
          );
          batteryModeStreamController.add(i.isEven);
        }

        await Future.delayed(const Duration(milliseconds: 100));

        expect(allEvents.length, 30);
      });
    });

    group('Timeout and delay scenarios', () {
      test('should handle slow getter responses', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer(
          (_) => Future.delayed(const Duration(milliseconds: 500), () => 50.0),
        );

        final ecoMode = buildEcoMode();
        final future = ecoMode.getBatteryLevel();

        // Should not complete immediately
        var completed = false;
        future.then((_) {
          completed = true;
        });

        await Future.delayed(const Duration(milliseconds: 100));
        expect(completed, false);

        await future;
        expect(completed, true);
      });

      test('should handle stream with long delays between emissions', () async {
        final ecoMode = buildEcoMode();
        final results = <double>[];

        ecoMode.batteryLevelEventStream.listen((value) {
          results.add(value);
        });

        batteryLevelStreamController.add(100.0);
        await Future.delayed(const Duration(milliseconds: 300));
        batteryLevelStreamController.add(50.0);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(results.length, 2);
      });
    });

    group('State consistency edge cases', () {
      test('should handle all thermal states', () async {
        final thermalStates = [
          ThermalState.safe,
          ThermalState.fair,
          ThermalState.serious,
          ThermalState.critical,
          ThermalState.unknown,
        ];

        for (final state in thermalStates) {
          when(
            () => ecoModeApi.getThermalState(),
          ).thenAnswer((_) async => state);
          final result = await buildEcoMode().getThermalState();
          expect(result, state);
        }
      });

      test('should handle all battery states', () async {
        final batteryStates = [
          BatteryState.charging,
          BatteryState.discharging,
          BatteryState.full,
          BatteryState.unknown,
        ];

        for (final state in batteryStates) {
          when(
            () => ecoModeApi.getBatteryState(),
          ).thenAnswer((_) async => state);
          final result = await buildEcoMode().getBatteryState();
          expect(result, state);
        }
      });

      test('should handle all connectivity types', () async {
        final connectivityTypes = [
          ConnectivityType.ethernet,
          ConnectivityType.wifi,
          ConnectivityType.mobile2g,
          ConnectivityType.mobile3g,
          ConnectivityType.mobile4g,
          ConnectivityType.mobile5g,
          ConnectivityType.none,
          ConnectivityType.unknown,
        ];

        for (final type in connectivityTypes) {
          when(
            () => ecoModeApi.getConnectivity(),
          ).thenAnswer((_) async => Connectivity(type: type));
          final result = await buildEcoMode().getConnectivity();
          expect(result.type, type);
        }
      });

      test('should handle wifi signal strength boundaries', () async {
        const strength = minWifiSignalStrength;
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: strength,
          ),
        );
        expect(await buildEcoMode().hasEnoughNetwork(), true);
      });

      test('should handle wifi signal strength below threshold', () async {
        const strength = minWifiSignalStrength - 10;
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: strength,
          ),
        );
        expect(await buildEcoMode().hasEnoughNetwork(), false);
      });
    });

    group('Memory constraints', () {
      test('should handle memory in ascending order', () async {
        when(
          () => ecoModeApi.getTotalMemory(),
        ).thenAnswer((_) async => 8000000000);
        when(
          () => ecoModeApi.getFreeMemory(),
        ).thenAnswer((_) async => 2000000000);

        final ecoMode = buildEcoMode();
        final total = await ecoMode.getTotalMemory();
        final free = await ecoMode.getFreeMemory();

        expect(free, lessThan(total));
      });

      test('should handle storage in ascending order', () async {
        when(
          () => ecoModeApi.getTotalStorage(),
        ).thenAnswer((_) async => 128000000000);
        when(
          () => ecoModeApi.getFreeStorage(),
        ).thenAnswer((_) async => 50000000000);

        final ecoMode = buildEcoMode();
        final total = await ecoMode.getTotalStorage();
        final free = await ecoMode.getFreeStorage();

        expect(free, lessThan(total));
      });
    });

    group('Stress tests', () {
      test('should handle 100 consecutive stream emissions', () async {
        final ecoMode = buildEcoMode();
        final results = <double>[];

        ecoMode.batteryLevelEventStream.listen((value) {
          results.add(value);
        });

        for (int i = 0; i < 100; i++) {
          batteryLevelStreamController.add(i.toDouble());
        }

        await Future.delayed(const Duration(milliseconds: 200));

        expect(results.length, 100);
        expect(results.first, 0.0);
        expect(results.last, 99.0);
      });

      test('should handle alternating battery states', () async {
        final ecoMode = buildEcoMode();
        final results = <BatteryState>[];

        ecoMode.batteryStateEventStream.listen((value) {
          results.add(value);
        });

        for (int i = 0; i < 20; i++) {
          batteryStateStreamController.add(
            i.isEven ? BatteryState.charging : BatteryState.discharging,
          );
        }

        await Future.delayed(const Duration(milliseconds: 100));

        expect(results.length, 20);
      });
    });
  });
}
