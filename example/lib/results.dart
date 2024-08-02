import 'package:flutter/material.dart';
import 'package:flutter_eco_mode/flutter_eco_mode.dart';

class ResultLine {
  final String label;
  final Color? labelColor;
  final Color? valueColor;
  final Future Function() future;
  final Stream Function()? stream;

  const ResultLine({
    required this.label,
    required this.future,
    this.stream,
    this.labelColor = Colors.black,
    this.valueColor = Colors.black,
  });
}

class ResultsView extends StatelessWidget {
  final List<ResultLine> resultLines;

  const ResultsView(this.resultLines, {super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 5 / 2,
      children: resultLines
          .map(
            (line) => [
              _ResultTitle(
                line.label,
                labelColor: line.labelColor,
              ),
              _Result(
                future: line.future,
                stream: line.stream,
                valueColor: line.valueColor,
              ),
            ],
          )
          .expand((e) => e)
          .toList(),
    );
  }
}

class _ResultTitle extends StatelessWidget {
  final String label;
  final Color? labelColor;

  const _ResultTitle(
    this.label, {
    this.labelColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return _ResultDecoration(
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: labelColor,
        ),
      ),
    );
  }
}

class _Result extends StatefulWidget {
  final Future Function() future;
  final Stream Function()? stream;
  final Color? valueColor;

  const _Result({
    required this.future,
    this.stream,
    this.valueColor = Colors.transparent,
  });

  @override
  State<_Result> createState() => _ResultState();
}

class _ResultState extends State<_Result> {
  late Future _future;
  late Stream _stream;

  @override
  void initState() {
    super.initState();
    _future = widget.future.call();
    if (widget.stream != null) {
      _stream = widget.stream!.call().withInitialValue(_future);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ResultDecoration(
      widget.stream != null
          ? StreamBuilder(
              stream: _stream,
              builder: (_, snapshot) => _ResultAsync(
                snapshot,
                color: widget.valueColor,
              ),
            )
          : FutureBuilder(
              future: _future,
              builder: (_, snapshot) => _ResultAsync(
                snapshot,
                color: widget.valueColor,
              ),
            ),
      alignment: Alignment.center,
    );
  }
}

class _ResultAsync<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Color? color;

  const _ResultAsync(
    this.snapshot, {
    super.key,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasData && snapshot.data != null) {
      return Text(
        '${snapshot.data}',
        style: TextStyle(color: color),
      );
    } else if (snapshot.hasError) {
      return Text(
        'not reachable',
        style: TextStyle(color: color),
      );
    } else {
      return const CircularProgressIndicator();
    }
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
