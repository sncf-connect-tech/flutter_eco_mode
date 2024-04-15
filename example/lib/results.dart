import 'package:flutter/material.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';
import 'package:flutter_eco_mode/flutter_eco_mode_platform_interface.dart';

class Results extends StatefulWidget {
  const Results({super.key});

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> {
  late FlutterEcoMode plugin;
  late Future<EcoRange?> ecoRange;

  @override
  void initState() {
    super.initState();
    plugin = FlutterEcoMode();
    ecoRange = plugin.getEcoRange();
  }

  @override
  Widget build(BuildContext context) {
    return _ResultsView(
      [
        _ResultLine(label: 'Platform info', widget: _ResultFuture(plugin.getPlatformInfo)),
        _ResultLine(label: 'Battery level', widget: _ResultFuture(plugin.getBatteryLevelPercent)),
        _ResultLine(label: 'Battery state', widget: _ResultFuture(plugin.getBatteryStateName)),
        _ResultLine(label: 'Is battery in low power mode', widget: _ResultFuture(plugin.isBatteryEcoMode)),
        _ResultLine(label: 'Low power mode event stream', widget: _ResultStream(plugin.lowPowerModeEventStream)),
        _ResultLine(label: 'Thermal state', widget: _ResultFuture(plugin.getThermalStateName)),
        _ResultLine(label: 'Processor count', widget: _ResultFuture(plugin.getProcessorCount)),
        _ResultLine(label: 'Total memory', widget: _ResultFuture(plugin.getTotalMemory)),
        _ResultLine(label: 'Free memory', widget: _ResultFuture(plugin.getFreeMemoryReachable)),
        _ResultLine(label: 'Total storage', widget: _ResultFuture(plugin.getTotalStorage)),
        _ResultLine(label: 'Free storage', widget: _ResultFuture(plugin.getFreeStorage)),
        _ResultLine(label: 'Is battery in eco mode', widget: _ResultFuture(plugin.isBatteryEcoMode)),
        _ResultLine(label: 'Eco score', widget: _ResultFuture(ecoRange.getScore)),
        _ResultLine(label: 'Device eco range', widget: _ResultFuture(ecoRange.getRange)),
        _ResultLine(label: 'Is low end device', widget: _ResultFuture(ecoRange.isLowEndDevice)),
      ],
    );
  }
}

extension on FlutterEcoMode {
  Future<String> getBatteryStateName() => getBatteryState().then((value) => value.name);

  Future<String> getThermalStateName() => getThermalState().then((value) => value.name);

  Future<String> getFreeMemoryReachable() =>
      getFreeMemory().then((value) => value > 0 ? value.toString() : "not reachable");

  Future<String> getBatteryLevelPercent() => getBatteryLevel()
      .then((value) => value != null && value >= 0 ? (value.toInt() * 100).toString() : "not reachable");
}

extension on Future<EcoRange?> {
  Future<String?> getScore() => then((value) => value?.score != null ? "${value!.score.toInt() * 100}/100" : null);

  Future<String?> getRange() => then((value) => value?.range.name);

  Future<String?> isLowEndDevice() => then((value) => value?.isLowEndDevice.toString());
}

class _ResultLine {
  final String label;
  final Widget widget;

  const _ResultLine({
    required this.label,
    required this.widget,
  });
}

class _ResultStream<T> extends StatelessWidget {
  final Stream<T> resultStream;

  const _ResultStream(this.resultStream);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: resultStream.timeout(const Duration(seconds: 1)),
      builder: (_, snapshot) => _ResultAsync(snapshot),
    );
  }
}

class _ResultFuture<T> extends StatefulWidget {
  final Future<T> Function() futureFunction;

  const _ResultFuture(this.futureFunction);

  @override
  State<_ResultFuture<T>> createState() => _ResultFutureState();
}

class _ResultFutureState<T> extends State<_ResultFuture<T>> {
  late Future<T> future;

  @override
  void initState() {
    future = widget.futureFunction().timeout(const Duration(seconds: 1));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: future,
      builder: (_, snapshot) => _ResultAsync(snapshot),
    );
  }
}

class _ResultAsync<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;

  const _ResultAsync(this.snapshot);

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasData && snapshot.data != null) {
      return Text('${snapshot.data}');
    } else if (snapshot.hasError) {
      return const Text('not reachable');
    } else {
      return const CircularProgressIndicator();
    }
  }
}

class _ResultsView extends StatelessWidget {
  final List<_ResultLine> resultLines;

  const _ResultsView(this.resultLines);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 5 / 2,
      children: resultLines
          .map(
            (line) => [
              _ResultTitle(line.label),
              _Result(line.widget),
            ],
          )
          .expand((e) => e)
          .toList(),
    );
  }
}

class _Result extends StatelessWidget {
  final Widget widget;

  const _Result(this.widget);

  @override
  Widget build(BuildContext context) {
    return _ResultDecoration(
      widget,
      alignment: Alignment.center,
    );
  }
}

class _ResultTitle extends StatelessWidget {
  final String label;

  const _ResultTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return _ResultDecoration(
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ResultDecoration extends StatelessWidget {
  final Widget widget;
  final Alignment? alignment;

  const _ResultDecoration(this.widget, {this.alignment});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment ?? Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: widget,
      ),
    );
  }
}
