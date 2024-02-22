import 'package:flutter/services.dart';
import 'package:flutter_eco_mode/flutter_eco_mode_platform_interface.dart';
import 'package:flutter_eco_mode/messages.g.dart';

/// An implementation of [FlutterEcoModePlatform] that uses pigeon.
class FlutterEcoMode extends FlutterEcoModePlatform {
  final EcoModeApi _api = EcoModeApi();
  static const eventChannel = EventChannel('sncf.connect.tech/battery.isLowPowerMode');

  @override
  Future<String?> getPlatformInfo() async {
    return await _api.getPlatformInfo();
  }

  @override
  Future<double?> getBatteryLevel() async {
    return await _api.getBatteryLevel();
  }

  @override
  Future<bool> isBatteryInLowPowerMode() async {
    return await _api.isBatteryInLowPowerMode();
  }

  @override
  Stream<bool> get lowPowerModeEventStream => _lowPowerModeStream();

  Stream<bool> _lowPowerModeStream() {
    final stream = eventChannel.receiveBroadcastStream();
    return stream.map((event) => event);
  }

  @override
  Future<BatteryState> getBatteryState() async {
    return await _api.getBatteryState();
  }

  // TODO: implement Stream for battery state change

  @override
  Future<ThermalState> getThermalState() async {
    return await _api.getThermalState();
  }

  @override
  Future<int?> getProcessorCount() async {
    return await _api.getProcessorCount();
  }

  @override
  Future<int?> getTotalMemory() async {
    return await _api.getTotalMemory();
  }

  @override
  Future<int?> getFreeMemory() async {
    return await _api.getFreeMemory();
  }

  @override
  Future<int?> getTotalStorage() async {
    return await _api.getTotalStorage();
  }

  @override
  Future<int?> getFreeStorage() async {
    return await _api.getFreeStorage();
  }

  @override
  Future<bool> isLowEndDevice() async {
    return await _api.isLowEndDevice();
  }
}
