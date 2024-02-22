import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/messages.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/src/main/kotlin/sncf/connect/tech/flutter_eco_mode/Messages.g.kt',
  kotlinOptions: KotlinOptions(package: 'sncf.connect.tech.flutter_eco_mode'),
  swiftOut: 'ios/Classes/Messages.g.swift',
  swiftOptions: SwiftOptions(),
  dartPackageName: 'flutter_eco_mode',
))
enum BatteryState {
  charging,
  discharging,
  full,
  unknown,
}

enum ThermalState {
  safe, /// nominal value
  fair, /// device is getting warm, but not under throttling
  serious, /// device is getting warm and performance is throttled
  critical, /// performance is throttled, device is too hot
  unknown, /// unknown state
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

  bool isLowEndDevice();
}
