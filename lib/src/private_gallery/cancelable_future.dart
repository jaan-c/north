import 'package:async/async.dart';

class CancelledException implements Exception {
  @override
  String toString() => '${(CancelledException)}';
}

class CancelState {
  var _isCancelled = false;

  void checkIsCancelled() {
    if (_isCancelled) {
      throw CancelledException();
    }
  }

  void cancel() {
    _isCancelled = true;
  }
}

typedef CancelableComputation<T> = Future<T> Function(CancelState state);

class CancelableFuture<T> extends DelegatingFuture<T> {
  final CancelState _state;

  CancelableFuture._internal(this._state, Future<T> future) : super(future);

  factory CancelableFuture(CancelableComputation computation) {
    final state = CancelState();
    final future = computation(state);
    return CancelableFuture._internal(state, future);
  }

  void cancel() {
    _state.cancel();
  }
}
