import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';

class FlutterEcoModeTest extends FlutterEcoMode {
  final double batteryLevel;
  final int batteryLevelMsDelay;
  final BatteryState batteryState;
  final int batteryStateMsDelay;
  final ThermalState thermalState;
  final int thermalStateMsDelay;
  final bool isBatteryLowPowerMode;
  final int isBatteryInLowPowerModeMsDelay;
  final Future<double?> Function()? getBatteryLevelFuture;
  final Future<bool?> Function()? isBatteryInLowPowerModeFuture;
  final Future<BatteryState> Function()? getBatteryStateFuture;
  final Future<ThermalState> Function()? getThermalStateFuture;
  final Future<double?> Function()? getEcoScoreFuture;

  FlutterEcoModeTest({
    this.batteryLevel = 100,
    this.batteryLevelMsDelay = 0,
    this.batteryState = BatteryState.charging,
    this.batteryStateMsDelay = 0,
    this.thermalState = ThermalState.safe,
    this.thermalStateMsDelay = 0,
    this.isBatteryLowPowerMode = false,
    this.isBatteryInLowPowerModeMsDelay = 0,
    this.getBatteryLevelFuture,
    this.isBatteryInLowPowerModeFuture,
    this.getBatteryStateFuture,
    this.getThermalStateFuture,
    this.getEcoScoreFuture,
  });

  @override
  Future<double?> getBatteryLevel() =>
      getBatteryLevelFuture?.call() ?? Future.delayed(Duration(milliseconds: batteryLevelMsDelay), () => batteryLevel);

  @override
  Future<bool?> isBatteryInLowPowerMode() =>
      isBatteryInLowPowerModeFuture?.call() ??
      Future.delayed(Duration(milliseconds: isBatteryInLowPowerModeMsDelay), () => isBatteryLowPowerMode);

  @override
  Future<BatteryState> getBatteryState() =>
      getBatteryStateFuture?.call() ?? Future.delayed(Duration(milliseconds: batteryStateMsDelay), () => batteryState);

  @override
  Future<ThermalState> getThermalState() =>
      getThermalStateFuture?.call() ?? Future.delayed(Duration(milliseconds: thermalStateMsDelay), () => thermalState);
}

class EcoModeApiTest extends EcoModeApi {
  final double ecoScore;
  final Future<double?> Function()? getEcoScoreFuture;

  EcoModeApiTest({
    this.ecoScore = 1.0,
    this.getEcoScoreFuture,
  });

  @override
  Future<double?> getEcoScore() => getEcoScoreFuture?.call() ?? Future.value(ecoScore);
}
