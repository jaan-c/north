import 'dart:async';
import 'dart:collection';

typedef FutureCallback<T> = Future<T> Function();

/// A queue of future callbacks that is ran one by one in FIFO order.
class FutureQueue<T> {
  final Queue<_Pair<FutureCallback<T>, Completer<T>>> _queue = Queue();

  var _isRunning = false;
  var _isDisposed = false;

  Future<T> add(FutureCallback<T> callback) {
    if (_isDisposed) {
      throw StateError(
          'Attempting to add on already disposed ${(FutureQueue)}.');
    }

    final completer = Completer<T>();
    _queue.add(_Pair(callback, completer));

    if (!_isRunning) {
      _run();
    }

    return completer.future;
  }

  Future<void> _run() async {
    _isRunning = true;

    while (_queue.isNotEmpty) {
      final pair = _queue.removeFirst();
      final callback = pair.first;
      final completer = pair.second;

      try {
        final result = await callback();
        completer.complete(result);
      } catch (e) {
        completer.completeError(e);
      }
    }

    _isRunning = false;
  }

  void clear() {
    _queue.clear();
  }

  void dispose() {
    clear();
    _isDisposed = true;
  }
}

class _Pair<T, V> {
  final T first;
  final V second;

  _Pair(this.first, this.second);
}
