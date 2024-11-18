import 'package:flutter/material.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode_example/extensions.dart';

import '../results.dart';

class ConnectivityStatePage extends StatelessWidget {
  final FlutterEcoMode ecoMode;

  const ConnectivityStatePage(this.ecoMode, {super.key});

  @override
  Widget build(BuildContext context) {
    return ResultsView(
      [
        ResultLine(
          label: 'Connectivity type',
          future: ecoMode.getConnectivityTypeName,
          stream: ecoMode.getConnectivityTypeStream,
        ),
        ResultLine(
          label: 'Wifi signal strength',
          future: ecoMode.getConnectivitySignalStrength,
          stream: ecoMode.getConnectivitySignalStrengthStream,
        ),
        ResultLine(
          label: 'Has enough Network',
          future: ecoMode.hasEnoughNetwork,
          stream: ecoMode.hasEnoughNetworkStream,
        ),
      ],
    );
  }
}
