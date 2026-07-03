import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/src/constants.dart';
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

  group('Simple Getters Tests', () {
    group('getPlatformInfo', () {
      test('should return platform info', () async {
        when(
          () => ecoModeApi.getPlatformInfo(),
        ).thenAnswer((_) async => 'iOS 17.0');
        expect(await buildEcoMode().getPlatformInfo(), 'iOS 17.0');
      });

      test('should return android platform', () async {
        when(
          () => ecoModeApi.getPlatformInfo(),
        ).thenAnswer((_) async => 'Android 14');
        expect(await buildEcoMode().getPlatformInfo(), 'Android 14');
      });
    });

    group('getBatteryLevel', () {
      test('should return battery level', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 85.5);
        expect(await buildEcoMode().getBatteryLevel(), 85.5);
      });

      test('should return 0 when battery is empty', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 0.0);
        expect(await buildEcoMode().getBatteryLevel(), 0.0);
      });

      test('should return 100 when battery is full', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 100.0);
        expect(await buildEcoMode().getBatteryLevel(), 100.0);
      });

      test('should handle decimal values', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 42.7);
        expect(await buildEcoMode().getBatteryLevel(), 42.7);
      });
    });

    group('getBatteryState', () {
      test('should return charging state', () async {
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.charging);
        expect(await buildEcoMode().getBatteryState(), BatteryState.charging);
      });

      test('should return discharging state', () async {
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.discharging);
        expect(
          await buildEcoMode().getBatteryState(),
          BatteryState.discharging,
        );
      });

      test('should return full state', () async {
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.full);
        expect(await buildEcoMode().getBatteryState(), BatteryState.full);
      });

      test('should return unknown state', () async {
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.unknown);
        expect(await buildEcoMode().getBatteryState(), BatteryState.unknown);
      });
    });

    group('getThermalState', () {
      test('should return safe thermal state', () async {
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.safe);
        expect(await buildEcoMode().getThermalState(), ThermalState.safe);
      });

      test('should return fair thermal state', () async {
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.fair);
        expect(await buildEcoMode().getThermalState(), ThermalState.fair);
      });

      test('should return serious thermal state', () async {
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.serious);
        expect(await buildEcoMode().getThermalState(), ThermalState.serious);
      });

      test('should return critical thermal state', () async {
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.critical);
        expect(await buildEcoMode().getThermalState(), ThermalState.critical);
      });
    });

    group('isBatteryInLowPowerMode', () {
      test('should return true when low power mode is enabled', () async {
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) async => true);
        expect(await buildEcoMode().isBatteryInLowPowerMode(), true);
      });

      test('should return false when low power mode is disabled', () async {
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) async => false);
        expect(await buildEcoMode().isBatteryInLowPowerMode(), false);
      });
    });

    group('getProcessorCount', () {
      test('should return processor count', () async {
        when(() => ecoModeApi.getProcessorCount()).thenAnswer((_) async => 8);
        expect(await buildEcoMode().getProcessorCount(), 8);
      });

      test('should return single core processor', () async {
        when(() => ecoModeApi.getProcessorCount()).thenAnswer((_) async => 1);
        expect(await buildEcoMode().getProcessorCount(), 1);
      });

      test('should return high core count', () async {
        when(() => ecoModeApi.getProcessorCount()).thenAnswer((_) async => 32);
        expect(await buildEcoMode().getProcessorCount(), 32);
      });
    });

    group('getTotalMemory', () {
      test('should return total memory', () async {
        when(
          () => ecoModeApi.getTotalMemory(),
        ).thenAnswer((_) async => 8000000000); // 8GB
        expect(await buildEcoMode().getTotalMemory(), 8000000000);
      });

      test('should handle large memory values', () async {
        when(
          () => ecoModeApi.getTotalMemory(),
        ).thenAnswer((_) async => 12000000000); // 12GB
        expect(await buildEcoMode().getTotalMemory(), 12000000000);
      });

      test('should handle small memory values', () async {
        when(
          () => ecoModeApi.getTotalMemory(),
        ).thenAnswer((_) async => 2000000000); // 2GB
        expect(await buildEcoMode().getTotalMemory(), 2000000000);
      });
    });

    group('getFreeMemory', () {
      test('should return free memory', () async {
        when(
          () => ecoModeApi.getFreeMemory(),
        ).thenAnswer((_) async => 2000000000); // 2GB
        expect(await buildEcoMode().getFreeMemory(), 2000000000);
      });

      test('should return zero when no free memory', () async {
        when(() => ecoModeApi.getFreeMemory()).thenAnswer((_) async => 0);
        expect(await buildEcoMode().getFreeMemory(), 0);
      });

      test('should return large free memory', () async {
        when(
          () => ecoModeApi.getFreeMemory(),
        ).thenAnswer((_) async => 6000000000); // 6GB
        expect(await buildEcoMode().getFreeMemory(), 6000000000);
      });
    });

    group('getTotalStorage', () {
      test('should return total storage', () async {
        when(
          () => ecoModeApi.getTotalStorage(),
        ).thenAnswer((_) async => 128000000000); // 128GB
        expect(await buildEcoMode().getTotalStorage(), 128000000000);
      });

      test('should handle various storage sizes', () async {
        when(
          () => ecoModeApi.getTotalStorage(),
        ).thenAnswer((_) async => 64000000000); // 64GB
        expect(await buildEcoMode().getTotalStorage(), 64000000000);
      });

      test('should handle small storage', () async {
        when(
          () => ecoModeApi.getTotalStorage(),
        ).thenAnswer((_) async => 32000000000); // 32GB
        expect(await buildEcoMode().getTotalStorage(), 32000000000);
      });
    });

    group('getFreeStorage', () {
      test('should return free storage', () async {
        when(
          () => ecoModeApi.getFreeStorage(),
        ).thenAnswer((_) async => 50000000000); // 50GB
        expect(await buildEcoMode().getFreeStorage(), 50000000000);
      });

      test('should return zero when storage is full', () async {
        when(() => ecoModeApi.getFreeStorage()).thenAnswer((_) async => 0);
        expect(await buildEcoMode().getFreeStorage(), 0);
      });

      test('should handle various free storage values', () async {
        when(
          () => ecoModeApi.getFreeStorage(),
        ).thenAnswer((_) async => 20000000000); // 20GB
        expect(await buildEcoMode().getFreeStorage(), 20000000000);
      });
    });

    group('Concurrent getters', () {
      test('should handle multiple concurrent getter calls', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 75.0);
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.discharging);
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.safe);

        final ecoMode = buildEcoMode();
        final results = await Future.wait([
          ecoMode.getBatteryLevel(),
          ecoMode.getBatteryState(),
          ecoMode.getThermalState(),
        ]);

        expect(results[0], 75.0);
        expect(results[1], BatteryState.discharging);
        expect(results[2], ThermalState.safe);
      });

      test('should handle all getters together', () async {
        when(() => ecoModeApi.getPlatformInfo()).thenAnswer((_) async => 'iOS');
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 50.0);
        when(() => ecoModeApi.getProcessorCount()).thenAnswer((_) async => 6);
        when(
          () => ecoModeApi.getTotalMemory(),
        ).thenAnswer((_) async => 4000000000);
        when(
          () => ecoModeApi.getFreeMemory(),
        ).thenAnswer((_) async => 1000000000);

        final ecoMode = buildEcoMode();
        final platform = await ecoMode.getPlatformInfo();
        final battery = await ecoMode.getBatteryLevel();
        final cores = await ecoMode.getProcessorCount();
        final totalMem = await ecoMode.getTotalMemory();
        final freeMem = await ecoMode.getFreeMemory();

        expect(platform, 'iOS');
        expect(battery, 50.0);
        expect(cores, 6);
        expect(totalMem, 4000000000);
        expect(freeMem, 1000000000);
      });

      test('should handle slow concurrent calls', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer(
          (_) => Future.delayed(const Duration(milliseconds: 100), () => 80.0),
        );
        when(() => ecoModeApi.getTotalMemory()).thenAnswer(
          (_) => Future.delayed(
            const Duration(milliseconds: 200),
            () => 8000000000,
          ),
        );

        final ecoMode = buildEcoMode();
        final startTime = DateTime.now();
        await Future.wait([
          ecoMode.getBatteryLevel(),
          ecoMode.getTotalMemory(),
        ]);
        final elapsed = DateTime.now().difference(startTime);

        // Should complete approximately in 200ms (parallel execution)
        expect(elapsed.inMilliseconds, lessThan(300));
      });
    });

    group('isBatteryEcoMode method', () {
      test('should return true when battery is low and discharging', () async {
        when(
          () => ecoModeApi.getBatteryLevel(),
        ).thenAnswer((_) async => minEnoughBattery - 5);
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.discharging);
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) async => false);
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.safe);

        final ecoMode = buildEcoMode();
        final result = await ecoMode.isBatteryEcoMode();

        expect(result, true);
      });

      test('should return true when battery is in low power mode', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 50.0);
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.charging);
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) async => true);
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.safe);

        final ecoMode = buildEcoMode();
        final result = await ecoMode.isBatteryEcoMode();

        expect(result, true);
      });

      test(
        'should return true when thermal state is serious or critical',
        () async {
          when(
            () => ecoModeApi.getBatteryLevel(),
          ).thenAnswer((_) async => 80.0);
          when(
            () => ecoModeApi.getBatteryState(),
          ).thenAnswer((_) async => BatteryState.charging);
          when(
            () => ecoModeApi.isBatteryInLowPowerMode(),
          ).thenAnswer((_) async => false);
          when(
            () => ecoModeApi.getThermalState(),
          ).thenAnswer((_) async => ThermalState.serious);

          final ecoMode = buildEcoMode();
          final result = await ecoMode.isBatteryEcoMode();

          expect(result, true);
        },
      );

      test('should return false when all conditions are healthy', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 80.0);
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.charging);
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) async => false);
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.safe);

        final ecoMode = buildEcoMode();
        final result = await ecoMode.isBatteryEcoMode();

        expect(result, false);
      });

      test('should handle thermal critical state', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 100.0);
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.charging);
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) async => false);
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.critical);

        final ecoMode = buildEcoMode();
        final result = await ecoMode.isBatteryEcoMode();

        expect(result, true);
      });

      test('should return false when battery is not discharging', () async {
        when(
          () => ecoModeApi.getBatteryLevel(),
        ).thenAnswer((_) async => minEnoughBattery - 5);
        when(
          () => ecoModeApi.getBatteryState(),
        ).thenAnswer((_) async => BatteryState.charging);
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenAnswer((_) async => false);
        when(
          () => ecoModeApi.getThermalState(),
        ).thenAnswer((_) async => ThermalState.safe);

        final ecoMode = buildEcoMode();
        final result = await ecoMode.isBatteryEcoMode();

        expect(result, false);
      });

      test('should throw exception when all API calls fail', () async {
        when(() => ecoModeApi.getBatteryLevel()).thenThrow(Exception('Error'));
        when(() => ecoModeApi.getBatteryState()).thenThrow(Exception('Error'));
        when(
          () => ecoModeApi.isBatteryInLowPowerMode(),
        ).thenThrow(Exception('Error'));
        when(() => ecoModeApi.getThermalState()).thenThrow(Exception('Error'));

        final ecoMode = buildEcoMode();

        expect(() => ecoMode.isBatteryEcoMode(), throwsA(isA<Exception>()));
      });
    });

    group('getDeviceRange method', () {
      test(
        'should return highEnd device for score > minScoreMidRangeDevice',
        () async {
          when(
            () => ecoModeApi.getEcoScore(),
          ).thenAnswer((_) async => minScoreMidRangeDevice + 0.1);

          final ecoMode = buildEcoMode();
          final result = await ecoMode.getDeviceRange();

          expect(result, isNotNull);
          expect(result.range, DeviceEcoRange.highEnd);
          expect(result.isLowEndDevice, false);
        },
      );

      test(
        'should return midRange device for score between thresholds',
        () async {
          when(() => ecoModeApi.getEcoScore()).thenAnswer(
            (_) async => (minScoreLowEndDevice + minScoreMidRangeDevice) / 2,
          );

          final ecoMode = buildEcoMode();
          final result = await ecoMode.getDeviceRange();

          expect(result, isNotNull);
          expect(result.range, DeviceEcoRange.midRange);
          expect(result.isLowEndDevice, false);
        },
      );

      test(
        'should return lowEnd device for score < minScoreLowEndDevice',
        () async {
          when(
            () => ecoModeApi.getEcoScore(),
          ).thenAnswer((_) async => minScoreLowEndDevice - 0.1);

          final ecoMode = buildEcoMode();
          final result = await ecoMode.getDeviceRange();

          expect(result, isNotNull);
          expect(result.range, DeviceEcoRange.lowEnd);
          expect(result.isLowEndDevice, true);
        },
      );

      test('should set correct score value in result', () async {
        const score = 0.75;
        when(() => ecoModeApi.getEcoScore()).thenAnswer((_) async => score);

        final ecoMode = buildEcoMode();
        final result = await ecoMode.getDeviceRange();

        expect(result.score, score);
      });

      test(
        'should return highEnd for boundary value at midRange threshold',
        () async {
          when(
            () => ecoModeApi.getEcoScore(),
          ).thenAnswer((_) async => minScoreMidRangeDevice);

          final ecoMode = buildEcoMode();
          final result = await ecoMode.getDeviceRange();

          expect(result.range, DeviceEcoRange.midRange);
        },
      );
    });

    group('hasEnoughNetwork method', () {
      test('should return true when WiFi signal is strong enough', () async {
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength + 10,
          ),
        );

        final ecoMode = buildEcoMode();
        final result = await ecoMode.hasEnoughNetwork();

        expect(result, true);
      });

      test('should return false when WiFi signal is too weak', () async {
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength - 10,
          ),
        );

        final ecoMode = buildEcoMode();
        final result = await ecoMode.hasEnoughNetwork();

        expect(result, false);
      });

      test('should return false when connection is not WiFi', () async {
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.mobile2g,
            wifiSignalStrength: null,
          ),
        );

        final ecoMode = buildEcoMode();
        final result = await ecoMode.hasEnoughNetwork();

        expect(result, false);
      });

      test('should return false when no connectivity', () async {
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.none,
            wifiSignalStrength: null,
          ),
        );

        final ecoMode = buildEcoMode();
        final result = await ecoMode.hasEnoughNetwork();

        expect(result, false);
      });

      test('should return false when WiFi signal strength is null', () async {
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: null,
          ),
        );

        final ecoMode = buildEcoMode();
        final result = await ecoMode.hasEnoughNetwork();

        expect(result, false);
      });

      test('should rethrow when API throws error', () async {
        when(
          () => ecoModeApi.getConnectivity(),
        ).thenThrow(Exception('API error'));

        final ecoMode = buildEcoMode();

        await expectLater(
          ecoMode.hasEnoughNetwork(),
          throwsA(isA<Exception>()),
        );
      });

      test('should return true at minimum WiFi signal threshold', () async {
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength,
          ),
        );

        final ecoMode = buildEcoMode();
        final result = await ecoMode.hasEnoughNetwork();

        expect(result, true);
      });
    });

    group('hasEnoughNetworkStream method', () {
      test('should emit true when WiFi signal is strong', () async {
        final ecoMode = buildEcoMode();
        final results = <bool>[];

        ecoMode.hasEnoughNetworkStream().listen((event) {
          results.add(event);
        });

        connectivityStreamController.add(
          Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength + 10,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(results.contains(true), true);
      });

      test('should emit false when WiFi signal is weak', () async {
        final ecoMode = buildEcoMode();
        final results = <bool>[];

        ecoMode.hasEnoughNetworkStream().listen((event) {
          results.add(event);
        });

        connectivityStreamController.add(
          Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength - 10,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(results.contains(false), true);
      });

      test('should emit multiple values on connectivity changes', () async {
        final ecoMode = buildEcoMode();
        final results = <bool>[];

        ecoMode.hasEnoughNetworkStream().listen((event) {
          results.add(event);
        });

        connectivityStreamController.add(
          Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength + 10,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        connectivityStreamController.add(
          Connectivity(
            type: ConnectivityType.mobile2g,
            wifiSignalStrength: null,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(results.length, greaterThanOrEqualTo(2));
      });

      test('should be broadcast stream', () async {
        final ecoMode = buildEcoMode();
        final results1 = <bool>[];
        final results2 = <bool>[];

        ecoMode.hasEnoughNetworkStream().listen((event) {
          results1.add(event);
        });

        ecoMode.hasEnoughNetworkStream().listen((event) {
          results2.add(event);
        });

        connectivityStreamController.add(
          Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength + 10,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(results1.isNotEmpty, true);
        expect(results2.isNotEmpty, true);
      });

      test('should emit false when no connectivity', () async {
        final ecoMode = buildEcoMode();
        final results = <bool>[];

        ecoMode.hasEnoughNetworkStream().listen((event) {
          results.add(event);
        });

        connectivityStreamController.add(
          Connectivity(type: ConnectivityType.none, wifiSignalStrength: null),
        );

        await Future.delayed(const Duration(milliseconds: 100));

        expect(results.contains(false), true);
      });
    });

    group('getConnectivity method', () {
      test('should return connectivity information', () async {
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: -50,
          ),
        );

        final ecoMode = buildEcoMode();
        final result = await ecoMode.getConnectivity();

        expect(result.type, ConnectivityType.wifi);
        expect(result.wifiSignalStrength, -50);
      });

      test('should return mobile connectivity', () async {
        when(() => ecoModeApi.getConnectivity()).thenAnswer(
          (_) async => Connectivity(
            type: ConnectivityType.mobile4g,
            wifiSignalStrength: null,
          ),
        );

        final ecoMode = buildEcoMode();
        final result = await ecoMode.getConnectivity();

        expect(result.type, ConnectivityType.mobile4g);
        expect(result.wifiSignalStrength, null);
      });
    });

    group('Connectivity stream', () {
      test('should return broadcast connectivity stream', () async {
        final ecoMode = buildEcoMode();
        final results1 = <Connectivity>[];
        final results2 = <Connectivity>[];

        ecoMode.connectivityStream.listen((event) {
          results1.add(event);
        });

        ecoMode.connectivityStream.listen((event) {
          results2.add(event);
        });

        final connectivity = Connectivity(
          type: ConnectivityType.wifi,
          wifiSignalStrength: -50,
        );

        connectivityStreamController.add(connectivity);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(results1.isNotEmpty, true);
        expect(results2.isNotEmpty, true);
        expect(results1.first.type, ConnectivityType.wifi);
      });

      test('should emit different connectivity types', () async {
        final ecoMode = buildEcoMode();
        final results = <Connectivity>[];

        ecoMode.connectivityStream.listen((event) {
          results.add(event);
        });

        connectivityStreamController.add(
          Connectivity(type: ConnectivityType.wifi, wifiSignalStrength: -50),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        connectivityStreamController.add(
          Connectivity(
            type: ConnectivityType.mobile2g,
            wifiSignalStrength: null,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        connectivityStreamController.add(
          Connectivity(type: ConnectivityType.none, wifiSignalStrength: null),
        );
        await Future.delayed(const Duration(milliseconds: 50));

        expect(results.length, greaterThanOrEqualTo(3));
        expect(
          results.map((c) => c.type).toList(),
          contains(ConnectivityType.wifi),
        );
        expect(
          results.map((c) => c.type).toList(),
          contains(ConnectivityType.mobile2g),
        );
        expect(
          results.map((c) => c.type).toList(),
          contains(ConnectivityType.none),
        );
      });
    });
  });
}
