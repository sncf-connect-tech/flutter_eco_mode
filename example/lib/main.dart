import 'package:flutter/material.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  final flutterEcoModePlugin = FlutterEcoMode();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _platformInfo;

  @override
  void initState() {
    super.initState();
    _getPlatformInfo();
  }

  void _getPlatformInfo() async {
    final platformInfo = await widget.flutterEcoModePlugin.getPlatformInfo();
    setState(() {
      _platformInfo = platformInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Platform info: $_platformInfo\n'),
              ElevatedButton(
                onPressed: () async {
                  final data =
                      await widget.flutterEcoModePlugin.getBatteryLevel();
                  print(data);
                  print(await widget.flutterEcoModePlugin.getBatteryState());
                  print(await widget.flutterEcoModePlugin
                      .isBatteryInLowPowerMode());
                },
                child: const Text('fetch battery data'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final data =
                      await widget.flutterEcoModePlugin.getProcessorCount();
                  print('Processor Count: $data');
                },
                child: const Text('Processor'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final total =
                      await widget.flutterEcoModePlugin.getTotalMemory();
                  final free =
                      await widget.flutterEcoModePlugin.getFreeMemory();
                  print('Memory => Total: $total, Free: $free');
                },
                child: const Text('Memory'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final total =
                      await widget.flutterEcoModePlugin.getTotalStorage();
                  final free =
                      await widget.flutterEcoModePlugin.getFreeStorage();
                  print('Storage => Total: $total, Free: $free');
                },
                child: const Text('Storage'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final data =
                      await widget.flutterEcoModePlugin.getThermalState();

                  print('Therma State: $data');
                },
                child: const Text('Thermal State'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final data =
                      await widget.flutterEcoModePlugin.isLowEndDevice();
                  print('Is Low End: $data');
                },
                child: const Text('Is Low End'),
              ),
              StreamBuilder<bool>(
                stream: widget.flutterEcoModePlugin.lowPowerModeEventStream,
                builder: (context, snapshot) {
                  print('Stream data: $snapshot');
                  if (snapshot.hasData) {
                    return Text('Stream data: ${snapshot.data}');
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
