import 'dart:async';

/// @internal
/// An optimized version of [Future.wait].
Future<void>? waitFuturesList(List<Future<void>> futures) {
  switch (futures.length) {
    case 0:
      return null;
    case 1:
      return futures[0];
    default:
      return Future.wait(futures).then(_ignore);
  }
}

/// Helper function to ignore future callback
void _ignore(Object? _) {}
