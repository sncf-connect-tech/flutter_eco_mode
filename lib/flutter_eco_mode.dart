import 'dart:async';
import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:flutter_eco_mode/flutter_eco_mode_platform_interface.dart';
import 'package:flutter_eco_mode/messages.g.dart';

const double minEnoughBattery = 10.0;
const double minScoreMidRangeDevice = 0.5;
const double minScoreLowEndDevice = 0.3;

/// An implementation of [FlutterEcoModePlatform] that uses pigeon.
class FlutterEcoMode extends FlutterEcoModePlatform {
  final EcoModeApi _api;

  FlutterEcoMode({EcoModeApi? api}) : _api = api ?? EcoModeApi();

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
  Future<bool?> isBatteryInLowPowerMode() async {
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
  Future<EcoRange?> getEcoRange() async {
    return _api.getEcoScore().then<EcoRange?>((value) {
      if (value == null) {
        throw Exception('Error while getting eco score');
      }
      final range = _buildRange(value);
      return EcoRange(score: value, range: range, isLowEndDevice: range == DeviceEcoRange.lowEnd);
    }).onError((error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    });
  }

  DeviceEcoRange _buildRange(double score) {
    switch (score) {
      case > minScoreMidRangeDevice:
        return DeviceEcoRange.highEnd;
      case > minScoreLowEndDevice:
        return DeviceEcoRange.midRange;
      default:
        return DeviceEcoRange.lowEnd;
    }
  }

  @override
  Future<bool?> isBatteryEcoMode() async {
    return Future.wait([
      _isNotEnoughBattery(),
      _isBatteryLowPowerMode(),
      _isSeriousAtLeastBatteryState(),
    ]).then<bool?>((List<bool?> value) {
      if (value.every((element) => element == null)) {
        throw Exception('Error while getting battery eco mode');
      }
      return value.any((element) => element ?? false);
    }).onError((error, stackTrace) {
      log(stackTrace.toString(), error: error);
      return null;
    });
  }

  Future<bool?> _isNotEnoughBattery() async {
    try {
      return Future.wait([
        Future<bool?>.value((await getBatteryLevel())?.isNotEnough),
        Future<bool?>.value((await getBatteryState()).isDischarging),
      ]).then((List<bool?> value) => value.every((bool? element) => element ?? false));
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
}

extension _BatteryLevel on double {
  bool get isNotEnough => this < minEnoughBattery;
}

extension on BatteryState {
  bool get isDischarging => this == BatteryState.discharging;
}

extension on ThermalState {
  bool get isSeriousAtLeast => this == ThermalState.serious || this == ThermalState.critical;
}
