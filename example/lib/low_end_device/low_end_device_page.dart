import 'package:flutter/material.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode_example/extensions.dart';
import 'package:flutter_eco_mode_example/results.dart';

class LowEndDevicePage extends StatefulWidget {
  final FlutterEcoMode ecoMode;

  const LowEndDevicePage(this.ecoMode, {super.key});

  @override
  State<LowEndDevicePage> createState() => _LowEndDevicePageState();
}

class _LowEndDevicePageState extends State<LowEndDevicePage> {
  late Future<DeviceRange?> deviceRange;

  @override
  void initState() {
    super.initState();
    deviceRange = widget.ecoMode.getDeviceRange();
  }

  @override
  Widget build(BuildContext context) {
    return ResultsView([
      ResultLine(
        label: 'Platform info',
        future: widget.ecoMode.getPlatformInfo,
      ),
      ResultLine(
        label: 'Processor count',
        future: widget.ecoMode.getProcessorCount,
      ),
      ResultLine(label: 'Total memory', future: widget.ecoMode.getTotalMemory),
      ResultLine(
        label: 'Free memory',
        future: widget.ecoMode.getFreeMemoryReachable,
      ),
      ResultLine(
        label: 'Total storage',
        future: widget.ecoMode.getTotalStorage,
      ),
      ResultLine(label: 'Free storage', future: widget.ecoMode.getFreeStorage),
      ResultLine(
        label: 'Device range score',
        labelColor: Colors.blue,
        valueColor: Colors.blue,
        future: deviceRange.getScore,
      ),
      ResultLine(
        label: 'Device range',
        labelColor: Colors.blue,
        valueColor: Colors.blue,
        future: deviceRange.getRange,
      ),
      ResultLine(
        label: 'Is low end device',
        labelColor: Colors.purple,
        valueColor: Colors.purple,
        future: deviceRange.isLowEndDevice,
      ),
    ]);
  }
}
