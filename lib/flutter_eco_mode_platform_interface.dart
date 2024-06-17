import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/messages.g.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of flutter_eco_mode must implement.
abstract class FlutterEcoModePlatform extends PlatformInterface {
  /// Constructs a FlutterEcoModePlatform.
  FlutterEcoModePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterEcoModePlatform _instance = FlutterEcoMode();

  /// The default instance of [FlutterEcoModePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterEcoMode].
  static FlutterEcoModePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterEcoModePlatform] when
  /// they register themselves.
  static set instance(FlutterEcoModePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Return the current platform info.
  Future<String?> getPlatformInfo();

  /// Return the current battery level.
  Future<double?> getBatteryLevel();

  /// Return a stream of battery level.
  Stream<double> get batteryLevelEventStream;

  /// Return the current battery state.
  Future<BatteryState> getBatteryState();

  /// Return a stream of battery state.
  Stream<BatteryState> get batteryStateEventStream;

  /// Return the current battery save mode.
  Future<bool?> isBatteryInLowPowerMode();

  /// Return a stream of battery save mode change.
  Stream<bool> get lowPowerModeEventStream;

  /// Return the current thermal state.
  Future<ThermalState> getThermalState();

  /// Return the number of core.
  Future<int?> getProcessorCount();

  /// Return the total RAM.
  Future<int?> getTotalMemory();

  /// Return the available RAM.
  Future<int?> getFreeMemory();

  /// Return the total disk space.
  Future<int?> getTotalStorage();

  /// Return the available disk space.
  Future<int?> getFreeStorage();

  /// Return if the battery is in eco mode.
  Future<bool?> isBatteryEcoMode();

  /// Return a stream is battery eco mode.
  Stream<bool?> get isBatteryEcoModeStream;

  /// Return the eco range.
  Future<EcoRange?> getEcoRange();
}

class EcoRange {
  double score;
  DeviceEcoRange range;
  bool isLowEndDevice;

  EcoRange({
    required this.score,
    required this.range,
    this.isLowEndDevice = false,
  });
}

enum DeviceEcoRange { lowEnd, midRange, highEnd }
