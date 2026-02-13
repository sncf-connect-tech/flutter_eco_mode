import 'package:flutter/material.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode_example/extensions.dart';
import 'package:flutter_eco_mode_example/results.dart';

class EcoBatteryPage extends StatelessWidget {
  final FlutterEcoMode ecoMode;

  const EcoBatteryPage(this.ecoMode, {super.key});

  @override
  Widget build(BuildContext context) {
    return ResultsView([
      ResultLine(label: 'Thermal state', future: ecoMode.getThermalStateName),
      ResultLine(
        label: 'Battery level event stream',
        future: ecoMode.getBatteryLevelPercent,
        stream: ecoMode.getBatteryLevelPercentStream,
      ),
      ResultLine(
        label: 'Battery state event stream',
        future: ecoMode.getBatteryStateName,
        stream: ecoMode.getBatteryStateStreamName,
      ),
      ResultLine(
        label: 'Low power mode event stream',
        future: ecoMode.isBatteryInLowPowerMode,
        stream: () => ecoMode.lowPowerModeEventStream,
      ),
      ResultLine(
        label: 'Is battery in eco mode event stream',
        labelColor: Colors.purple,
        valueColor: Colors.purple,
        future: ecoMode.isBatteryEcoMode,
        stream: () => ecoMode.isBatteryEcoModeStream,
      ),
    ]);
  }
}
