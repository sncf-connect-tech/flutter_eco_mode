import 'package:flutter_eco_mode/flutter_eco_mode.dart';

extension FlutterEcoModeExtension on FlutterEcoMode {
  Future<String> getBatteryStateName() =>
      getBatteryState().then((value) => value.name);

  Stream<String> getBatteryStateStreamName() =>
      batteryStateEventStream.map((value) => value.name);

  Future<String> getThermalStateName() =>
      getThermalState().then((value) => value.name);

  Future<String> getFreeMemoryReachable() => getFreeMemory()
      .then((value) => value > 0 ? value.toString() : "not reachable");

  Future<String> getBatteryLevelPercent() => getBatteryLevel().then((value) =>
      value != null && value > 0 ? "${value.toInt()} %" : "not reachable");

  Stream<String> getBatteryLevelPercentStream() => batteryLevelEventStream
      .map((value) => value > 0 ? "${value.toInt()} %" : "not reachable");

  Future<String> getConnectivityTypeName() =>
      getConnectivity().then((value) => value.type.name);

  Future<String> getConnectivitySignalStrength() => getConnectivity()
      .then((value) => value.wifiSignalStrength?.toString() ?? "not reachable");

  Stream<String> getConnectivityTypeStream() =>
      connectivityStream.map((value) => value.type.name);

  Stream<String> getConnectivitySignalStrengthStream() => connectivityStream
      .map((value) => value.wifiSignalStrength?.toString() ?? "not reachable");
}

extension FutureEcoRangeExtension on Future<DeviceRange?> {
  Future<String?> getScore() => then((value) =>
      value?.score != null ? "${(value!.score * 100).toInt()}/100" : null);

  Future<String?> getRange() => then((value) => value?.range.name);

  Future<String?> isLowEndDevice() =>
      then((value) => value?.isLowEndDevice.toString());
}
