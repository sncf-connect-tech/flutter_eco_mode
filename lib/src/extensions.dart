import 'package:flutter_eco_mode/src/constants.dart';
import 'package:flutter_eco_mode/src/messages.g.dart';

extension BatteryLevelExtensions on double {
  bool get isNotEnough => this < minEnoughBattery;
}

extension BatteryStateExtensions on BatteryState {
  bool get isDischarging => this == BatteryState.discharging;
}

extension ThermalStateExtensions on ThermalState {
  bool get isSeriousAtLeast =>
      this == ThermalState.serious || this == ThermalState.critical;
}

extension ConnectivityExtensions on Connectivity {
  bool get isEnough =>
      type != ConnectivityType.unknown &&
      (_isMobileEnoughNetwork ||
          _isWifiEnoughNetwork ||
          type == ConnectivityType.ethernet);

  bool get _isMobileEnoughNetwork => [
    ConnectivityType.mobile5g,
    ConnectivityType.mobile4g,
    ConnectivityType.mobile3g,
  ].contains(type);

  bool get _isWifiEnoughNetwork =>
      ConnectivityType.wifi == type && wifiSignalStrength != null
          ? wifiSignalStrength! >= minWifiSignalStrength
          : false;
}
