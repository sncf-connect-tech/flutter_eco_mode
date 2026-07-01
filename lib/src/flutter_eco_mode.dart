import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_eco_mode/src/eco_mode_exceptions.dart';
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

  /// Runs [call] and converts any [PlatformException] coming from the
  /// native side into a typed [EcoModeException].
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (error) {
      throw error.toEcoModeException();
    }
  }

  /// Returns a human-readable string describing the current OS/device
  /// (e.g. OS version, device model).
  ///
  /// Returns a [String] built from native platform information.
  ///
  /// Exceptions: none expected under normal conditions. May complete with a
  /// [PlatformException] if the platform channel itself fails.
  @override
  Future<String> getPlatformInfo() async {
    return await _api.getPlatformInfo();
  }

  /// Returns the current battery level of the device.
  ///
  /// Returns a [double] between `0.0` and `100.0` representing the battery
  /// charge percentage.
  ///
  /// Exceptions: none expected under normal conditions. May complete with a
  /// [PlatformException] if the platform channel itself fails.
  @override
  Future<double> getBatteryLevel() async {
    return await _api.getBatteryLevel();
  }

  /// Checks whether the device's battery saver / low power mode is enabled.
  ///
  /// Returns a [bool], `true` if low power mode is currently active.
  ///
  /// Exceptions: none expected under normal conditions. May complete with a
  /// [PlatformException] if the platform channel itself fails.
  @override
  Future<bool> isBatteryInLowPowerMode() async {
    return await _api.isBatteryInLowPowerMode();
  }

  /// Returns the current charging state of the battery (charging,
  /// discharging, full or unknown).
  ///
  /// Returns a [BatteryState] value.
  ///
  /// Exceptions: none expected under normal conditions. May complete with a
  /// [PlatformException] if the platform channel itself fails.
  @override
  Future<BatteryState> getBatteryState() async {
    return await _api.getBatteryState();
  }

  /// Returns the current thermal state of the device (how hot it is
  /// running, and whether performance is being throttled).
  ///
  /// Returns a [ThermalState] value.
  ///
  /// Exceptions: none expected under normal conditions. May complete with a
  /// [PlatformException] if the platform channel itself fails.
  @override
  Future<ThermalState> getThermalState() async {
    return await _api.getThermalState();
  }

  /// Returns the number of processor cores available on the device.
  ///
  /// Returns an [int] representing the core count.
  ///
  /// Exceptions: none expected under normal conditions. May complete with a
  /// [PlatformException] if the platform channel itself fails.
  @override
  Future<int> getProcessorCount() async {
    return await _api.getProcessorCount();
  }

  /// Returns the total physical RAM installed on the device.
  ///
  /// Returns an [int] representing the total memory in bytes.
  ///
  /// Exceptions: none expected under normal conditions. May complete with a
  /// [PlatformException] if the platform channel itself fails.
  @override
  Future<int> getTotalMemory() async {
    return await _api.getTotalMemory();
  }

  /// Returns the amount of RAM currently available/free on the device.
  ///
  /// Returns an [int] representing the free memory in bytes.
  ///
  /// Exceptions: none expected under normal conditions. May complete with a
  /// [PlatformException] if the platform channel itself fails.
  @override
  Future<int> getFreeMemory() async {
    return await _api.getFreeMemory();
  }

  /// Returns the total disk storage capacity of the device.
  ///
  /// Returns an [int] representing the total storage in bytes.
  ///
  /// Exceptions: throws [EcoModeStorageException] (code `STORAGE_ERROR`) if
  /// the native platform fails to read the volume capacity.
  @override
  Future<int> getTotalStorage() async {
    return _guard(_api.getTotalStorage);
  }

  /// Returns the amount of disk storage currently available/free on the
  /// device.
  ///
  /// Returns an [int] representing the free storage in bytes.
  ///
  /// Exceptions: throws [EcoModeStorageException] (code `STORAGE_ERROR`) if
  /// the native platform fails to read the volume capacity.
  @override
  Future<int> getFreeStorage() async {
    return _guard(_api.getFreeStorage);
  }

  /// Computes an eco-friendliness score for the device based on its RAM,
  /// processor count and storage capacity, and derives a [DeviceRange] from
  /// it (low-end, mid-range or high-end).
  ///
  /// Returns a [DeviceRange] containing the raw `score` and the resolved
  /// `range`/`isLowEndDevice` helpers.
  ///
  /// Exceptions: throws [EcoModeStorageException] (code `STORAGE_ERROR`) if
  /// the native platform fails to read the storage capacity needed to
  /// compute the score, or [EcoModeGenericException] for any other
  /// unmapped native error.
  @override
  Future<DeviceRange> getDeviceRange() async {
    return _guard(() => _api.getEcoScore().then<DeviceRange>(DeviceRange.new));
  }

  /// Aggregates battery level, discharging state, low power mode and
  /// thermal state to determine whether the app should switch to an
  /// eco/degraded experience to save battery.
  ///
  /// Returns a [bool], `true` if at least one of the underlying signals
  /// (low battery + discharging, low power mode enabled, or a serious/
  /// critical thermal state) indicates the app should run in eco mode.
  ///
  /// Exceptions: this is a pure pass-through. If any of the underlying
  /// native calls (battery level, battery state, low power mode, thermal
  /// state) fails, its original error/exception is rethrown as-is.
  @override
  Future<bool> isBatteryEcoMode() async {
    final results = await Future.wait([
      _isNotEnoughBattery(),
      isBatteryInLowPowerMode(),
      (getThermalState().then((value) => value.isSeriousAtLeast)),
    ]);
    return results.any((element) => element);
  }

  /// Returns whether the battery is both below the "not enough" threshold
  /// and currently discharging.
  ///
  /// Returns a [bool].
  ///
  /// Exceptions: propagates whatever error [getBatteryLevel] or
  /// [getBatteryState] throws, unmodified.
  Future<bool> _isNotEnoughBattery() async {
    final level = await getBatteryLevel();
    final state = await getBatteryState();
    return level.isNotEnough && state.isDischarging;
  }

  /// A broadcast stream emitting `true`/`false` whenever the device's low
  /// power mode is toggled.
  ///
  /// Returns a `Stream<bool>`.
  ///
  /// Exceptions: errors from the underlying native event channel are
  /// forwarded as stream errors and should be handled via the stream's
  /// `onError`/`catchError`.
  @override
  Stream<bool> get lowPowerModeEventStream =>
      _batteryModeStream ??= batteryMode().asBroadcastStream();

  /// A broadcast stream emitting the battery level (0.0 to 100.0) whenever
  /// it changes.
  ///
  /// Returns a `Stream<double>`.
  ///
  /// Exceptions: errors from the underlying native event channel are
  /// forwarded as stream errors and should be handled via the stream's
  /// `onError`/`catchError`.
  @override
  Stream<double> get batteryLevelEventStream =>
      _batteryLevelStream ??= batteryLevel().asBroadcastStream();

  /// A broadcast stream emitting the [BatteryState] whenever it changes
  /// (charging, discharging, full, unknown).
  ///
  /// Returns a `Stream<BatteryState>`.
  ///
  /// Exceptions: errors from the underlying native event channel are
  /// forwarded as stream errors and should be handled via the stream's
  /// `onError`/`catchError`.
  @override
  Stream<BatteryState> get batteryStateEventStream =>
      _batteryStateStream ??= batteryState().asBroadcastStream();

  /// A broadcast stream combining battery level, battery state and low
  /// power mode to emit whether the app is currently considered to be in
  /// eco mode. See [isBatteryEcoMode] for the underlying logic.
  ///
  /// Returns a `Stream<bool>`.
  ///
  /// Exceptions: errors from the underlying native event channels are
  /// forwarded as stream errors and should be handled via the stream's
  /// `onError`/`catchError`.
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

  /// A broadcast stream emitting the current [Connectivity] (network type
  /// and, for Wifi, signal strength) whenever it changes.
  ///
  /// Returns a `Stream<Connectivity>`.
  ///
  /// Exceptions: errors from the underlying native event channel are
  /// forwarded as stream errors and should be handled via the stream's
  /// `onError`/`catchError`.
  @override
  Stream<Connectivity> get connectivityStream =>
      _connectivityStream ??= connectivity().asBroadcastStream();

  /// Returns a one-shot snapshot of the current network connectivity
  /// (type and, for Wifi, signal strength).
  ///
  /// Returns a [Connectivity] object.
  ///
  /// Exceptions: throws [EcoModePermissionException] (code
  /// `PERMISSION_ERROR`) or [EcoModePermissionDeniedException] (code
  /// `PERMISSION_DENIED`) on Android if the required phone-state
  /// permission is missing or access is refused, or
  /// [EcoModeGenericException] for any other unmapped native error.
  @override
  Future<Connectivity> getConnectivity() async {
    return _guard(_api.getConnectivity);
  }

  /// Returns whether the current network connectivity is good enough for
  /// the app to work reliably (based on [Connectivity.isEnough]).
  ///
  /// Returns a `bool?`: `true`/`false` when the connectivity could be
  /// determined, or `null` if it could not be resolved.
  ///
  /// Exceptions: none. Any underlying error is caught, logged, and results
  /// in a `null` return value instead of throwing.
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

  /// A broadcast stream emitting whether the current network connectivity
  /// is good enough for the app to work reliably, updated whenever
  /// [connectivityStream] emits a new value.
  ///
  /// Returns a `Stream<bool?>`, where `null` means the connectivity state
  /// could not be resolved.
  ///
  /// Exceptions: none expected; unresolvable states are represented as
  /// `null` values rather than stream errors.
  @override
  Stream<bool?> hasEnoughNetworkStream() {
    return connectivityStream
        .map((event) => event.isEnough)
        .asBroadcastStream();
  }
}
