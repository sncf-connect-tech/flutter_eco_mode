import 'dart:collection';

/// @internal
/// Provides [mapNotNull] extension method on [Iterable].
extension MapNotNullIterableExtension<T> on Iterable<T> {
  /// @internal
  /// Maps each element and its index to a new value.
  Iterable<R> mapIndexed<R>(R Function(int index, T element) transform) sync* {
    var index = 0;
    for (final e in this) {
      yield transform(index++, e);
    }
  }
}

/// @internal
/// Provides [removeFirstElements] extension method on [Queue].
extension RemoveFirstElementsQueueExtension<T> on Queue<T> {
  /// @internal
  /// Removes the first [count] elements of this queue.
  void removeFirstElements(int count) {
    for (var i = 0; i < count; i++) {
      removeFirst();
    }
  }
}
