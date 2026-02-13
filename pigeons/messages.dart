import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/messages.g.dart',
    dartOptions: DartOptions(),
    kotlinOut:
        'android/src/main/kotlin/sncf/connect/tech/flutter_eco_mode/Messages.g.kt',
    kotlinOptions: KotlinOptions(package: 'sncf.connect.tech.flutter_eco_mode'),
    swiftOut: 'ios/flutter_eco_mode/Sources/flutter-eco-mode/Messages.g.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: 'flutter_eco_mode',
  ),
)
enum BatteryState { charging, discharging, full, unknown }

enum ThermalState {
  /// nominal value
  safe,

  /// device is getting warm, but not under throttling
  fair,

  /// device is getting warm and performance is throttled
  serious,

  /// performance is throttled, device is too hot
  critical,

  /// unknown state
  unknown,
}

class Connectivity {
  final ConnectivityType type;
  final int? wifiSignalStrength;

  Connectivity({required this.type, this.wifiSignalStrength});
}

enum ConnectivityType {
  ethernet,
  wifi,
  mobile2g,
  mobile3g,
  mobile4g,
  mobile5g,
  none,
  unknown,
}

@HostApi()
abstract class EcoModeApi {
  String getPlatformInfo();

  double getBatteryLevel();

  BatteryState getBatteryState();

  bool isBatteryInLowPowerMode();

  ThermalState getThermalState();

  int getProcessorCount();

  int getTotalMemory();

  int getFreeMemory();

  int getTotalStorage();

  int getFreeStorage();

  double? getEcoScore();

  Connectivity getConnectivity();
}
