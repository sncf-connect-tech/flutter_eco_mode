import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/flutter_eco_mode_platform_interface.dart';
import 'package:flutter_eco_mode/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockEventChannel extends Mock implements EventChannel {}

class MockEcoModeApi extends Mock implements EcoModeApi {}

void main() {
  late EventChannel batteryLevelEventChannel;
  late EventChannel batteryStateEventChannel;
  late EventChannel batteryModeEventChannel;
  late EventChannel connectivityStateEventChannel;
  late EcoModeApi ecoModeApi;

  FlutterEcoMode buildEcoMode() => FlutterEcoMode(
        api: ecoModeApi,
        batteryLevelEventChannel: batteryLevelEventChannel,
        batteryStatusEventChannel: batteryStateEventChannel,
        batteryModeEventChannel: batteryModeEventChannel,
        connectivityStateEventChannel: connectivityStateEventChannel,
      );

  setUp(() {
    ecoModeApi = MockEcoModeApi();
    when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 100.0);
    when(() => ecoModeApi.getBatteryState())
        .thenAnswer((_) async => BatteryState.charging);
    when(() => ecoModeApi.isBatteryInLowPowerMode())
        .thenAnswer((_) async => false);
    when(() => ecoModeApi.getThermalState())
        .thenAnswer((_) async => ThermalState.safe);
    when(() => ecoModeApi.getConnectivity())
        .thenAnswer((_) async => Connectivity(type: ConnectivityType.unknown));
    batteryLevelEventChannel = MockEventChannel();
    batteryStateEventChannel = MockEventChannel();
    batteryModeEventChannel = MockEventChannel();
    connectivityStateEventChannel = MockEventChannel();
    when(() => batteryLevelEventChannel.receiveBroadcastStream())
        .thenAnswer((_) => Stream<double>.value(100.0));
    when(() => batteryStateEventChannel.receiveBroadcastStream())
        .thenAnswer((_) => Stream<String>.value(BatteryState.charging.name));
    when(() => batteryModeEventChannel.receiveBroadcastStream())
        .thenAnswer((_) => Stream<bool>.value(false));
    when(() => connectivityStateEventChannel.receiveBroadcastStream())
        .thenAnswer((_) => Stream<String>.value('{"type": "UNKNOWN"}'));
  });

  group('Battery Eco Mode', () {
    group(
      'Future isBatteryEcoMode',
      () {
        test('should return false initially', () async {
          expect(await buildEcoMode().isBatteryEcoMode(), false);
        });

        test('should return true when not enough battery and discharging',
            () async {
          when(() => ecoModeApi.getBatteryLevel())
              .thenAnswer((_) async => minEnoughBattery - 1);
          when(() => ecoModeApi.getBatteryState())
              .thenAnswer((_) async => BatteryState.discharging);
          expect(await buildEcoMode().isBatteryEcoMode(), true);
        });

        test('should return true when battery in low power mode', () async {
          when(() => ecoModeApi.isBatteryInLowPowerMode())
              .thenAnswer((_) async => true);
          expect(await buildEcoMode().isBatteryEcoMode(), true);
        });

        test('should return true when thermal state is critical', () async {
          when(() => ecoModeApi.getThermalState())
              .thenAnswer((_) async => ThermalState.critical);
          expect(await buildEcoMode().isBatteryEcoMode(), true);
        });

        test('should return true when thermal state is serious', () async {
          when(() => ecoModeApi.getThermalState())
              .thenAnswer((_) async => ThermalState.serious);
          expect(await buildEcoMode().isBatteryEcoMode(), true);
        });

        test(
            'should return true when thermal state is serious and battery level is in error',
            () async {
          when(() => ecoModeApi.getThermalState())
              .thenAnswer((_) async => ThermalState.serious);
          when(() => ecoModeApi.getBatteryLevel())
              .thenAnswer((_) => Future.error('error battery level'));
          expect(await buildEcoMode().isBatteryEcoMode(), true);
        });

        test(
            'should return false when thermal state is safe and battery level is in error',
            () async {
          when(() => ecoModeApi.getThermalState())
              .thenAnswer((_) async => ThermalState.safe);
          when(() => ecoModeApi.getBatteryLevel())
              .thenAnswer((_) => Future.error('error battery level'));
          expect(await buildEcoMode().isBatteryEcoMode(), false);
        });

        test('should return null when impossible to get battery info',
            () async {
          when(() => ecoModeApi.getBatteryLevel())
              .thenAnswer((_) => Future.error('error battery level'));
          when(() => ecoModeApi.getBatteryState())
              .thenAnswer((_) => Future.error('error battery state'));
          when(() => ecoModeApi.isBatteryInLowPowerMode())
              .thenAnswer((_) => Future.error('error battery low power mode'));
          when(() => ecoModeApi.getThermalState())
              .thenAnswer((_) => Future.error('error thermal state'));
          expect(await buildEcoMode().isBatteryEcoMode(), null);
        });

        test('should wait all the future to complete the statement', () async {
          when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) =>
              Future.delayed(const Duration(milliseconds: 100), () => 100.0));
          when(() => ecoModeApi.getBatteryState()).thenAnswer((_) =>
              Future.delayed(const Duration(milliseconds: 200),
                  () => BatteryState.charging));
          when(() => ecoModeApi.isBatteryInLowPowerMode()).thenAnswer((_) =>
              Future.delayed(const Duration(milliseconds: 300), () => false));
          when(() => ecoModeApi.getThermalState()).thenAnswer((_) =>
              Future.delayed(const Duration(milliseconds: 400),
                  () => ThermalState.serious));
          expect(await buildEcoMode().isBatteryEcoMode(), true);
        });
      },
    );

    group(
      'Stream isBatteryEcoMode',
      () {
        test('should return false initially', () async {
          buildEcoMode().isBatteryEcoModeStream.listen(expectAsync1((event) {
                expect(event, false);
              }, count: 1));
        });

        test('should return false when not enough battery and charging',
            () async {
          when(() => batteryLevelEventChannel.receiveBroadcastStream())
              .thenAnswer((_) => Stream<double>.value(minEnoughBattery - 1));
          when(() => batteryStateEventChannel.receiveBroadcastStream())
              .thenAnswer(
                  (_) => Stream<String>.value(BatteryState.charging.name));
          buildEcoMode().isBatteryEcoModeStream.listen(expectAsync1((event) {
                expect(event, false);
              }, count: 1));
        });

        test('should return false when enough battery and discharging',
            () async {
          when(() => batteryLevelEventChannel.receiveBroadcastStream())
              .thenAnswer((_) => Stream<double>.value(minEnoughBattery + 1));
          when(() => batteryStateEventChannel.receiveBroadcastStream())
              .thenAnswer(
                  (_) => Stream<String>.value(BatteryState.discharging.name));
          buildEcoMode().isBatteryEcoModeStream.listen(expectAsync1((event) {
                expect(event, false);
              }, count: 1));
        });

        test('should return true when not enough battery and discharging',
            () async {
          when(() => batteryLevelEventChannel.receiveBroadcastStream())
              .thenAnswer((_) => Stream<double>.value(minEnoughBattery - 1));
          when(() => batteryStateEventChannel.receiveBroadcastStream())
              .thenAnswer(
                  (_) => Stream<String>.value(BatteryState.discharging.name));
          buildEcoMode().isBatteryEcoModeStream.listen(expectAsync1((event) {
                expect(event, true);
              }, count: 1));
        });

        test('should return true when battery in low power mode', () async {
          when(() => ecoModeApi.isBatteryInLowPowerMode())
              .thenAnswer((_) async => true);
          buildEcoMode().isBatteryEcoModeStream.listen(expectAsync1((event) {
                expect(event, true);
              }, count: 1));
        });

        test('should return nothing when battery state event is not a string',
            () async {
          when(() => batteryStateEventChannel.receiveBroadcastStream())
              .thenAnswer((_) => Stream<bool>.value(false));
          try {
            await buildEcoMode()
                .batteryStateEventStream
                .timeout(const Duration(milliseconds: 1))
                .first;
          } on TimeoutException catch (e) {
            expect(e.message, 'No stream event');
          }
        });

        test('should return nothing when level battery event is not a double',
            () async {
          when(() => batteryLevelEventChannel.receiveBroadcastStream())
              .thenAnswer((_) => Stream<bool>.value(false));
          try {
            await buildEcoMode()
                .batteryLevelEventStream
                .timeout(const Duration(milliseconds: 1))
                .first;
          } on TimeoutException catch (e) {
            expect(e.message, 'No stream event');
          }
        });
      },
    );
  });

  group('Connectivity', () {
    group(
      'Future hasEnoughNetwork',
      () {
        test('should return null when connectivity is unknown', () async {
          expect(await buildEcoMode().hasEnoughNetwork(), null);
        });

        void mockConnectivityType(ConnectivityType type,
            {int? wifiSignalStrength}) {
          when(() => ecoModeApi.getConnectivity()).thenAnswer((_) =>
              Future.value(Connectivity(
                  type: type, wifiSignalStrength: wifiSignalStrength)));
        }

        void assertHasEnoughNetwork(bool? expected) async {
          expect(await buildEcoMode().hasEnoughNetwork(), expected);
        }

        test('should return true when connectivity type is ethernet', () async {
          mockConnectivityType(ConnectivityType.ethernet);
          assertHasEnoughNetwork(true);
        });

        test('should return false when connectivity type is mobile2g',
            () async {
          mockConnectivityType(ConnectivityType.mobile2g);
          assertHasEnoughNetwork(false);
        });

        test('should return true when connectivity type is mobile3g', () async {
          mockConnectivityType(ConnectivityType.mobile3g);
          assertHasEnoughNetwork(true);
        });

        test('should return true when connectivity type is mobile4g', () async {
          mockConnectivityType(ConnectivityType.mobile4g);
          assertHasEnoughNetwork(true);
        });

        test('should return true when connectivity type is mobile5g', () async {
          mockConnectivityType(ConnectivityType.mobile5g);
          assertHasEnoughNetwork(true);
        });

        test(
            'should return true when connectivity type is WIFI and signal is enough',
            () async {
          mockConnectivityType(ConnectivityType.wifi,
              wifiSignalStrength: minWifiSignalStrength);
          assertHasEnoughNetwork(true);
        });

        test(
            'should return false when connectivity type is WIFI and signal is not enough',
            () async {
          mockConnectivityType(ConnectivityType.wifi,
              wifiSignalStrength: minWifiSignalStrength - 1);
          assertHasEnoughNetwork(false);
        });

        test(
            'should return false when connectivity type is WIFI and signal is null',
            () async {
          mockConnectivityType(ConnectivityType.wifi);
          assertHasEnoughNetwork(false);
        });
      },
    );

    group(
      'Stream hasEnoughNetwork',
      () {
        test('should return null when connectivity is unknown', () async {
          buildEcoMode().hasEnoughNetworkStream().listen(expectAsync1((event) {
                expect(event, null);
              }, count: 1));
        });

        void mockConnectivityType(String type, {int? wifiSignalStrength}) {
          when(() => connectivityStateEventChannel
              .receiveBroadcastStream()).thenAnswer((_) => Stream<
                  String>.value(
              '{"type": "$type", "wifiSignalStrength": $wifiSignalStrength}'));
        }

        void assertHasEnoughNetwork(bool? expected) {
          buildEcoMode().hasEnoughNetworkStream().listen(expectAsync1((event) {
                expect(event, expected);
              }, count: 1));
        }

        test('should return null when connectivity type not exists', () async {
          mockConnectivityType('NOT_EXISTS');
          assertHasEnoughNetwork(null);
        });

        test('should return true when connectivity type is ETHERNET', () async {
          mockConnectivityType('ETHERNET');
          assertHasEnoughNetwork(true);
        });

        test('should return false when connectivity type is MOBILE2G',
            () async {
          mockConnectivityType('MOBILE2G');
          assertHasEnoughNetwork(false);
        });

        test('should return true when connectivity type is MOBILE3G', () async {
          mockConnectivityType('MOBILE3G');
          assertHasEnoughNetwork(true);
        });

        test('should return true when connectivity type is MOBILE4G', () async {
          mockConnectivityType('MOBILE4G');
          assertHasEnoughNetwork(true);
        });

        test('should return true when connectivity type is MOBILE5G', () async {
          mockConnectivityType('MOBILE5G');
          assertHasEnoughNetwork(true);
        });

        test(
            'should return true when connectivity type is WIFI and signal is enough',
            () async {
          mockConnectivityType('WIFI',
              wifiSignalStrength: minWifiSignalStrength);
          assertHasEnoughNetwork(true);
        });

        test(
            'should return false when connectivity type is WIFI and signal is not enough',
            () async {
          mockConnectivityType('WIFI',
              wifiSignalStrength: minWifiSignalStrength - 1);
          assertHasEnoughNetwork(false);
        });

        test(
            'should return false when connectivity type is WIFI and signal is null',
            () async {
          mockConnectivityType('WIFI');
          assertHasEnoughNetwork(false);
        });
      },
    );
  });

  group(
    'Device Range getEcoScore',
    () {
      test('should return null when get eco score error', () async {
        when(() => ecoModeApi.getEcoScore())
            .thenAnswer((_) => Future.error('error eco score'));
        expect(await buildEcoMode().getDeviceRange(), null);
      });

      test('should return null when get eco score null', () async {
        when(() => ecoModeApi.getEcoScore())
            .thenAnswer((_) => Future.value(null));
        expect(await buildEcoMode().getDeviceRange(), null);
      });

      test('should return low end device', () async {
        when(() => ecoModeApi.getEcoScore())
            .thenAnswer((_) => Future.value(minScoreLowEndDevice));
        final deviceRange = await buildEcoMode().getDeviceRange();
        expect(deviceRange!.score, minScoreLowEndDevice);
        expect(deviceRange.range, DeviceEcoRange.lowEnd);
        expect(deviceRange.isLowEndDevice, true);
      });

      test('should return mid range device', () async {
        when(() => ecoModeApi.getEcoScore())
            .thenAnswer((_) => Future.value(minScoreMidRangeDevice));
        final deviceRange = await buildEcoMode().getDeviceRange();
        expect(deviceRange!.score, minScoreMidRangeDevice);
        expect(deviceRange.range, DeviceEcoRange.midRange);
        expect(deviceRange.isLowEndDevice, false);
      });

      test('should return high end device', () async {
        when(() => ecoModeApi.getEcoScore())
            .thenAnswer((_) => Future.value(minScoreMidRangeDevice + 0.1));
        final deviceRange = await buildEcoMode().getDeviceRange();
        expect(deviceRange!.score, minScoreMidRangeDevice + 0.1);
        expect(deviceRange.range, DeviceEcoRange.highEnd);
        expect(deviceRange.isLowEndDevice, false);
      });
    },
  );
}
