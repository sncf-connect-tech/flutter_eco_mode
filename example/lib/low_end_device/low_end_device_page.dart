import 'package:flutter/material.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/flutter_eco_mode_platform_interface.dart';
import 'package:flutter_eco_mode_example/extensions.dart';
import 'package:flutter_eco_mode_example/results.dart';

class LowEndDevicePage extends StatefulWidget {
  final FlutterEcoMode ecoMode;

  const LowEndDevicePage(this.ecoMode, {super.key});

  @override
  State<LowEndDevicePage> createState() => _LowEndDevicePageState();
}

class _LowEndDevicePageState extends State<LowEndDevicePage> {
  late Future<EcoRange?> ecoRange;

  @override
  void initState() {
    super.initState();
    ecoRange = widget.ecoMode.getEcoRange();
  }

  @override
  Widget build(BuildContext context) {
    return ResultsView(
      [
        ResultLine(
          label: 'Platform info',
          future: widget.ecoMode.getPlatformInfo,
        ),
        ResultLine(
          label: 'Processor count',
          future: widget.ecoMode.getProcessorCount,
        ),
        ResultLine(
          label: 'Total memory',
          future: widget.ecoMode.getTotalMemory,
        ),
        ResultLine(
          label: 'Free memory',
          future: widget.ecoMode.getFreeMemoryReachable,
        ),
        ResultLine(
          label: 'Total storage',
          future: widget.ecoMode.getTotalStorage,
        ),
        ResultLine(
          label: 'Free storage',
          future: widget.ecoMode.getFreeStorage,
        ),
        ResultLine(
          label: 'Eco range score',
          labelColor: Colors.blue,
          valueColor: Colors.blue,
          future: ecoRange.getScore,
        ),
        ResultLine(
          label: 'Device eco range',
          labelColor: Colors.blue,
          valueColor: Colors.blue,
          future: ecoRange.getRange,
        ),
        ResultLine(
          label: 'Is low end device',
          labelColor: Colors.purple,
          valueColor: Colors.purple,
          future: ecoRange.isLowEndDevice,
        ),
      ],
    );
  }
}


