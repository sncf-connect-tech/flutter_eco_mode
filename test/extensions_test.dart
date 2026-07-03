import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_eco_mode/src/constants.dart';
import 'package:flutter_eco_mode/src/extensions.dart';
import 'package:flutter_eco_mode/src/messages.g.dart';

void main() {
  group('BatteryLevelExtensions', () {
    group('isNotEnough', () {
      test('should return true when battery level is below minimum', () {
        final batteryLevel = minEnoughBattery - 1.0;
        expect(batteryLevel.isNotEnough, true);
      });

      test('should return false when battery level is exactly minimum', () {
        expect(minEnoughBattery.isNotEnough, false);
      });

      test('should return false when battery level is above minimum', () {
        final batteryLevel = minEnoughBattery + 1.0;
        expect(batteryLevel.isNotEnough, false);
      });

      test('should return true when battery level is 0', () {
        expect((0.0).isNotEnough, true);
      });

      test('should return false when battery level is 100', () {
        expect((100.0).isNotEnough, false);
      });

      test('should return true when battery level is very low', () {
        expect((0.1).isNotEnough, true);
      });
    });
  });

  group('BatteryStateExtensions', () {
    group('isDischarging', () {
      test('should return true when battery state is discharging', () {
        expect(BatteryState.discharging.isDischarging, true);
      });

      test('should return false when battery state is charging', () {
        expect(BatteryState.charging.isDischarging, false);
      });

      test('should return false when battery state is unknown', () {
        expect(BatteryState.unknown.isDischarging, false);
      });

      test('should return false when battery state is full', () {
        expect(BatteryState.full.isDischarging, false);
      });
    });
  });

  group('ThermalStateExtensions', () {
    group('isSeriousAtLeast', () {
      test('should return true when thermal state is critical', () {
        expect(ThermalState.critical.isSeriousAtLeast, true);
      });

      test('should return true when thermal state is serious', () {
        expect(ThermalState.serious.isSeriousAtLeast, true);
      });

      test('should return false when thermal state is fair', () {
        expect(ThermalState.fair.isSeriousAtLeast, false);
      });

      test('should return false when thermal state is safe', () {
        expect(ThermalState.safe.isSeriousAtLeast, false);
      });

      test('should return false when thermal state is unknown', () {
        expect(ThermalState.unknown.isSeriousAtLeast, false);
      });
    });
  });

  group('ConnectivityExtensions', () {
    group('isEnough', () {
      test('should return false when connectivity type is unknown', () {
        final connectivity = Connectivity(type: ConnectivityType.unknown);
        expect(connectivity.isEnough, false);
      });

      test('should return true when connectivity type is ethernet', () {
        final connectivity = Connectivity(type: ConnectivityType.ethernet);
        expect(connectivity.isEnough, true);
      });

      test('should return false when connectivity type is mobile2g', () {
        final connectivity = Connectivity(type: ConnectivityType.mobile2g);
        expect(connectivity.isEnough, false);
      });

      test('should return true when connectivity type is mobile3g', () {
        final connectivity = Connectivity(type: ConnectivityType.mobile3g);
        expect(connectivity.isEnough, true);
      });

      test('should return true when connectivity type is mobile4g', () {
        final connectivity = Connectivity(type: ConnectivityType.mobile4g);
        expect(connectivity.isEnough, true);
      });

      test('should return true when connectivity type is mobile5g', () {
        final connectivity = Connectivity(type: ConnectivityType.mobile5g);
        expect(connectivity.isEnough, true);
      });

      test(
        'should return true when connectivity type is wifi and signal is enough',
        () {
          final connectivity = Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength,
          );
          expect(connectivity.isEnough, true);
        },
      );

      test(
        'should return true when connectivity type is wifi and signal is above minimum',
        () {
          final connectivity = Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength + 1,
          );
          expect(connectivity.isEnough, true);
        },
      );

      test(
        'should return false when connectivity type is wifi and signal is below minimum',
        () {
          final connectivity = Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength - 1,
          );
          expect(connectivity.isEnough, false);
        },
      );

      test(
        'should return false when connectivity type is wifi and signal is null',
        () {
          final connectivity = Connectivity(type: ConnectivityType.wifi);
          expect(connectivity.isEnough, false);
        },
      );

      test(
        'should return true when connectivity type is wifi and signal is 0',
        () {
          final connectivity = Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: 0,
          );
          expect(connectivity.isEnough, true);
        },
      );

      test(
        'should return false when connectivity type is wifi and signal is below threshold',
        () {
          final connectivity = Connectivity(
            type: ConnectivityType.wifi,
            wifiSignalStrength: minWifiSignalStrength - 1,
          );
          expect(connectivity.isEnough, false);
        },
      );
    });
  });
}
