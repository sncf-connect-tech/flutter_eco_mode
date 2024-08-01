import 'package:flutter/material.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode_example/eco_battery/eco_battery_page.dart';
import 'package:flutter_eco_mode_example/low_end_device/low_end_device_page.dart';
import 'package:flutter_eco_mode_example/wrapper_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            elevation: 5,
            shadowColor: Colors.grey,
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            titleTextStyle: TextStyle(fontSize: 25),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 5,
              shadowColor: Colors.grey,
              minimumSize: const Size(250, 50),
              textStyle: const TextStyle(fontSize: 25),
            ),
          ),
        ),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Example'),
          ),
          body: const _MyApp(),
        ),
      );
}

class _MyApp extends StatefulWidget {
  const _MyApp();

  @override
  State<_MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<_MyApp> {
  late FlutterEcoMode plugin;

  @override
  void initState() {
    super.initState();
    plugin = FlutterEcoMode();
  }

  @override
  void dispose() {
    plugin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => WrapperPage(
                    LowEndDevicePage(plugin),
                    title: "Low End Device"),
              ),
            ),
            child: const Text("Low End Device"),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) => WrapperPage(
                  EcoBatteryPage(plugin),
                  title: "Eco Battery",
                ),
              ),
            ),
            child: const Text("Eco Battery"),
          ),
        ],
      ),
    );
  }
}
