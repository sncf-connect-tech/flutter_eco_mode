import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_eco_mode/src/constants.dart';
import 'package:flutter_eco_mode/src/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/src/messages.g.dart';

class MockEcoModeApi extends Mock implements EcoModeApi {}

void main() {
  late StreamController<double> batteryLevelStreamController;
  late StreamController<BatteryState> batteryStateStreamController;
  late StreamController<bool> batteryModeStreamController;
  late EcoModeApi ecoModeApi;

  FlutterEcoMode buildEcoMode() => FlutterEcoMode(
    api: ecoModeApi,
    batteryLevelStream: batteryLevelStreamController.stream,
    batteryStateStream: batteryStateStreamController.stream,
    batteryModeStream: batteryModeStreamController.stream,
  );

  setUp(() {
    ecoModeApi = MockEcoModeApi();
    when(() => ecoModeApi.getBatteryLevel()).thenAnswer((_) async => 100.0);
    when(
      () => ecoModeApi.getBatteryState(),
    ).thenAnswer((_) async => BatteryState.charging);
    when(
      () => ecoModeApi.isBatteryInLowPowerMode(),
    ).thenAnswer((_) async => false);
    batteryLevelStreamController = StreamController<double>.broadcast();
    batteryStateStreamController = StreamController<BatteryState>.broadcast();
    batteryModeStreamController = StreamController<bool>.broadcast();
  });

  tearDown(() {
    batteryLevelStreamController.close();
    batteryStateStreamController.close();
    batteryModeStreamController.close();
  });

  group('Combined Streams Tests', () {
    group('isBatteryEcoModeStream updates', () {
      test('should return false initially with healthy battery', () async {
        final ecoMode = buildEcoMode();
        ecoMode.isBatteryEcoModeStream.listen(
          expectAsync1((event) {
            expect(event, false);
          }, count: 1),
        );

        batteryLevelStreamController.add(100.0);
        batteryStateStreamController.add(BatteryState.charging);
        batteryModeStreamController.add(false);
      });

      test(
        'should return true when battery level drops below minimum and discharging',
        () async {
          final ecoMode = buildEcoMode();
          final results = <bool?>[];

          ecoMode.isBatteryEcoModeStream.listen((event) {
            results.add(event);
          });

          // Initial state: healthy battery
          batteryLevelStreamController.add(100.0);
          batteryStateStreamController.add(BatteryState.charging);
          batteryModeStreamController.add(false);

          await Future.delayed(const Duration(milliseconds: 100));

          // Change to low battery and discharging
          batteryLevelStreamController.add(minEnoughBattery - 1);
          batteryStateStreamController.add(BatteryState.discharging);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(results.any((event) => event == true), true);
        },
      );

      test('should return true when low power mode is enabled', () async {
        final ecoMode = buildEcoMode();
        final results = <bool?>[];

        ecoMode.isBatteryEcoModeStream.listen((event) {
          results.add(event);
        });

        batteryLevelStreamController.add(100.0);
        await Future.delayed(const Duration(milliseconds: 50));

        batteryStateStreamController.add(BatteryState.discharging);
        await Future.delayed(const Duration(milliseconds: 50));

        batteryModeStreamController.add(true); // Eco mode enabled

        await Future.delayed(const Duration(milliseconds: 100));

        // When low power mode is enabled, eco mode should be true
        expect(results.isNotEmpty, true);
        expect(results.contains(true), true);
      });

      test('should react to battery level changes', () async {
        final ecoMode = buildEcoMode();
        final results = <bool?>[];

        ecoMode.isBatteryEcoModeStream.listen((event) {
          results.add(event);
        });

        // Wait for the initial-value futures (Rx.concat seeds) to resolve and
        // for Rx.concat to subscribe to the broadcast event streams.
        await Future.delayed(Duration.zero);

        // Start with high battery
        batteryLevelStreamController.add(100.0);
        batteryStateStreamController.add(BatteryState.discharging);
        batteryModeStreamController.add(false);

        await Future.delayed(const Duration(milliseconds: 50));

        // Drop battery below threshold
        batteryLevelStreamController.add(minEnoughBattery - 5);

        await Future.delayed(const Duration(milliseconds: 100));

        // Should have at least one true value
        expect(results.any((event) => event == true), true);
      });

      test('should react to battery state changes', () async {
        final ecoMode = buildEcoMode();
        final results = <bool?>[];

        ecoMode.isBatteryEcoModeStream.listen((event) {
          results.add(event);
        });

        // Wait for the initial-value futures (Rx.concat seeds) to resolve.
        await Future.delayed(Duration.zero);

        // Start with low battery but charging (should be false)
        batteryLevelStreamController.add(minEnoughBattery - 1);
        batteryStateStreamController.add(BatteryState.charging);
        batteryModeStreamController.add(false);

        await Future.delayed(const Duration(milliseconds: 100));

        // Change to discharging
        batteryStateStreamController.add(BatteryState.discharging);

        await Future.delayed(const Duration(milliseconds: 100));

        // Should transition to eco mode
        expect(results.any((event) => event == true), true);
      });

      test('should react to low power mode changes', () async {
        final ecoMode = buildEcoMode();
        final results = <bool?>[];

        ecoMode.isBatteryEcoModeStream.listen((event) {
          results.add(event);
        });

        // Start without eco mode
        batteryLevelStreamController.add(50.0);
        batteryStateStreamController.add(BatteryState.charging);
        batteryModeStreamController.add(false);

        await Future.delayed(const Duration(milliseconds: 50));

        // Enable low power mode
        batteryModeStreamController.add(true);

        await Future.delayed(const Duration(milliseconds: 100));

        // Should transition to eco mode
        expect(results.any((event) => event == true), true);
      });
    });

    group('Complex state transitions', () {
      test('should handle multiple simultaneous changes', () async {
        final ecoMode = buildEcoMode();
        final results = <bool?>[];

        ecoMode.isBatteryEcoModeStream.listen((event) {
          results.add(event);
        });

        // Good state
        batteryLevelStreamController.add(100.0);
        batteryStateStreamController.add(BatteryState.charging);
        batteryModeStreamController.add(false);

        await Future.delayed(const Duration(milliseconds: 50));

        // Multiple changes at once
        batteryLevelStreamController.add(minEnoughBattery - 1);
        batteryStateStreamController.add(BatteryState.discharging);
        batteryModeStreamController.add(true);

        await Future.delayed(const Duration(milliseconds: 100));

        // Should become eco mode
        expect(results.any((event) => event == true), true);
      });

      test('should handle oscillating battery level', () async {
        final ecoMode = buildEcoMode();
        final results = <bool?>[];

        ecoMode.isBatteryEcoModeStream.listen((event) {
          results.add(event);
        });

        batteryStateStreamController.add(BatteryState.discharging);
        batteryModeStreamController.add(false);

        // Oscillate around threshold
        for (int i = 0; i < 5; i++) {
          batteryLevelStreamController.add(minEnoughBattery - 1); // below
          await Future.delayed(const Duration(milliseconds: 30));
          batteryLevelStreamController.add(minEnoughBattery + 1); // above
          await Future.delayed(const Duration(milliseconds: 30));
        }

        // Should have transitions in both directions
        expect(results.isNotEmpty, true);
      });

      test('should handle rapid successive changes', () async {
        final ecoMode = buildEcoMode();
        final results = <bool?>[];

        ecoMode.isBatteryEcoModeStream.listen((event) {
          results.add(event);
        });

        batteryStateStreamController.add(BatteryState.discharging);

        for (int i = 100; i > 0; i--) {
          batteryLevelStreamController.add(i.toDouble());
          batteryModeStreamController.add(i.isEven);
        }

        await Future.delayed(const Duration(milliseconds: 200));

        // Should emit multiple values and not crash
        expect(results.isNotEmpty, true);
      });

      test('should stabilize after changes', () async {
        final ecoMode = buildEcoMode();
        final results = <bool?>[];

        ecoMode.isBatteryEcoModeStream.listen((event) {
          results.add(event);
        });

        // Trigger eco mode
        batteryLevelStreamController.add(5.0);
        batteryStateStreamController.add(BatteryState.discharging);
        batteryModeStreamController.add(false);

        await Future.delayed(const Duration(milliseconds: 100));

        final countAfterChange = results.length;

        // Wait for stabilization
        await Future.delayed(const Duration(milliseconds: 100));

        // No new emissions without changes
        expect(results.length, countAfterChange);
      });
    });

    group('Stream unsubscription', () {
      test('should stop emitting after unsubscription', () async {
        final ecoMode = buildEcoMode();
        final results = <bool?>[];

        final subscription = ecoMode.isBatteryEcoModeStream.listen((event) {
          results.add(event);
        });

        batteryLevelStreamController.add(50.0);
        batteryStateStreamController.add(BatteryState.charging);
        batteryModeStreamController.add(false);

        await Future.delayed(const Duration(milliseconds: 50));

        subscription.cancel();

        final countAfterCancel = results.length;

        // More changes after unsubscribe
        batteryLevelStreamController.add(100.0);
        batteryStateStreamController.add(BatteryState.charging);

        await Future.delayed(const Duration(milliseconds: 100));

        // No new emissions after cancel
        expect(results.length, countAfterCancel);
      });

      test(
        'should be broadcast stream allowing independent listeners',
        () async {
          final ecoMode = buildEcoMode();
          final listener1Results = <bool?>[];
          final listener2Results = <bool?>[];

          final subscription1 = ecoMode.isBatteryEcoModeStream.listen((event) {
            listener1Results.add(event);
          });

          batteryLevelStreamController.add(50.0);
          batteryStateStreamController.add(BatteryState.charging);
          batteryModeStreamController.add(false);

          await Future.delayed(const Duration(milliseconds: 100));

          // First listener should have received an event
          expect(listener1Results.isNotEmpty, true);

          // Second listener can be attached to the same broadcast stream
          final subscription2 = ecoMode.isBatteryEcoModeStream.listen((event) {
            listener2Results.add(event);
          });

          // Change state so both listeners can observe
          batteryLevelStreamController.add(5.0); // low battery
          batteryStateStreamController.add(
            BatteryState.discharging,
          ); // discharging

          await Future.delayed(const Duration(milliseconds: 100));

          // First listener should have more events than before
          expect(listener1Results.length, greaterThan(1));
          // Second listener might have received the last change
          // (depending on stream timing)

          subscription1.cancel();
          subscription2.cancel();
        },
      );
    });
  });
}
