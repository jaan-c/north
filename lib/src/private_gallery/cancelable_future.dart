import 'package:async/async.dart';

class CancelledOperationException implements Exception {
  @override
  String toString() => '${(CancelledOperationException)}';
}

class CancelState {
  var _isCancelled = false;

  void checkIsCancelled() {
    if (_isCancelled) {
      throw CancelledOperationException();
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
