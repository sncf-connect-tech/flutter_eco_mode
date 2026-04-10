import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:flutter_eco_mode/src/extensions.dart';
import 'package:flutter_eco_mode/src/flutter_eco_mode_platform_interface.dart';
import 'package:flutter_eco_mode/src/messages.g.dart';
import 'package:flutter_eco_mode/src/streams/combine_latest.dart';

/// An implementation of [FlutterEcoModePlatform] that uses pigeon.
class FlutterEcoMode extends FlutterEcoModePlatform {
  final EcoModeApi _api;
  Stream<double>? _batteryLevelStream;
  Stream<BatteryState>? _batteryStateStream;
  Stream<bool>? _batteryModeStream;
  Stream<Connectivity>? _connectivityStream;

  FlutterEcoMode({
    @visibleForTesting EcoModeApi? api,
    @visibleForTesting Stream<double>? batteryLevelStream,
    @visibleForTesting Stream<BatteryState>? batteryStateStream,
    @visibleForTesting Stream<bool>? batteryModeStream,
    @visibleForTesting Stream<Connectivity>? connectivityStream,
  }) : _api = api ?? EcoModeApi(),
       _batteryLevelStream = batteryLevelStream,
       _batteryStateStream = batteryStateStream,
       _batteryModeStream = batteryModeStream,
       _connectivityStream = connectivityStream;

  @override
  Future<String> getPlatformInfo() async {
    return await _api.getPlatformInfo();
  }

  @override
  Future<double> getBatteryLevel() async {
    return await _api.getBatteryLevel();
  }

  @override
  Future<bool> isBatteryInLowPowerMode() async {
    return await _api.isBatteryInLowPowerMode();
  }

  @override
  Future<BatteryState> getBatteryState() async {
    return await _api.getBatteryState();
  }

  @override
  Future<ThermalState> getThermalState() async {
    return await _api.getThermalState();
  }

  @override
  Future<int> getProcessorCount() async {
    return await _api.getProcessorCount();
  }

  @override
  Future<int> getTotalMemory() async {
    return await _api.getTotalMemory();
  }

  @override
  Future<int> getFreeMemory() async {
    return await _api.getFreeMemory();
  }

  @override
  Future<int> getTotalStorage() async {
    return await _api.getTotalStorage();
  }

  @override
  Future<int> getFreeStorage() async {
    return await _api.getFreeStorage();
  }

  @override
  Future<DeviceRange> getDeviceRange() async {
    return _api.getEcoScore().then<DeviceRange>(DeviceRange.new);
  }

  @override
  Future<bool> isBatteryEcoMode() async {
    return Future.wait([
          _isNotEnoughBattery(),
          _isBatteryLowPowerMode(),
          _isSeriousAtLeastBatteryState(),
        ])
        .then<bool>((List<bool?> value) {
          if (value.every((element) => element == null)) {
            throw Exception('Error while getting battery eco mode');
          }
          return value.any((element) => element ?? false);
        })
        .onError((error, stackTrace) {
          log(stackTrace.toString(), error: error);
          throw Exception('Error while getting battery eco mode');
        });
  }

  Future<bool?> _isNotEnoughBattery() async {
    try {
      return Future.wait([
        Future<bool?>.value((await getBatteryLevel()).isNotEnough),
        Future<bool?>.value((await getBatteryState()).isDischarging),
      ]).then(
        (List<bool?> value) => value.every((bool? element) => element ?? false),
      );
    } catch (error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    }
  }

  Future<bool?> _isBatteryLowPowerMode() async {
    try {
      return await isBatteryInLowPowerMode();
    } catch (error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    }
  }

  Future<bool?> _isSeriousAtLeastBatteryState() async {
    try {
      return Future.value((await getThermalState()).isSeriousAtLeast);
    } catch (error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    }
  }

  @override
  Stream<bool> get lowPowerModeEventStream =>
      _batteryModeStream ??= batteryMode().asBroadcastStream();

  @override
  Stream<double> get batteryLevelEventStream =>
      _batteryLevelStream ??= batteryLevel().asBroadcastStream();

  @override
  Stream<BatteryState> get batteryStateEventStream =>
      _batteryStateStream ??= batteryState().asBroadcastStream();

  @override
  Stream<bool> get isBatteryEcoModeStream =>
      CombineLatestStream.list([
        _isNotEnoughBatteryStream(),
        lowPowerModeEventStream,
      ]).map((event) => event.any((element) => element)).asBroadcastStream();

  Stream<bool> _isNotEnoughBatteryStream() =>
      CombineLatestStream.list([
        batteryLevelEventStream.map((event) => event.isNotEnough),
        batteryStateEventStream.map((event) => event.isDischarging),
      ]).map((event) => event.every((element) => element)).asBroadcastStream();

  @override
  Stream<Connectivity> get connectivityStream =>
      _connectivityStream ??= connectivity().asBroadcastStream();

  @override
  Future<Connectivity> getConnectivity() async {
    return await _api.getConnectivity();
  }

  @override
  Future<bool?> hasEnoughNetwork() async {
    try {
      final connectivity = await getConnectivity();
      return connectivity.isEnough;
    } catch (error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    }
  }

  @override
  Stream<bool?> hasEnoughNetworkStream() {
    return connectivityStream
        .map((event) => event.isEnough)
        .asBroadcastStream();
  }
}
