import 'package:async/async.dart';

class CancelledException implements Exception {
  @override
  String toString() => '${(CancelledException)}';
}

abstract class CancelState {
  void checkIsCancelled();
  void cancel();
}

class _CancelStateReal implements CancelState {
  var _isCancelled = false;

  @override
  void checkIsCancelled() {
    if (_isCancelled) {
      throw CancelledException();
    }
  }

  @override
  void cancel() {
    _isCancelled = true;
  }
}

class _CancelStateDelegate implements CancelState {
  CancelState _state;

  CancelState get state => _state;

  set state(CancelState newState) {
    if (newState is _CancelStateDelegate) {
      _state = newState._state;
    } else {
      _state = newState;
    }
  }

  _CancelStateDelegate() : _state = _CancelStateReal();

  @override
  void checkIsCancelled() {
    state.checkIsCancelled();
  }

  @override
  void cancel() {
    state.cancel();
  }
}

typedef CancelableComputation<T> = Future<T> Function(CancelState state);

class CancelableFuture<T> extends DelegatingFuture<T> {
  final _CancelStateDelegate _state;

  CancelableFuture._internal(this._state, Future<T> future) : super(future);

  factory CancelableFuture(CancelableComputation computation) {
    final state = _CancelStateDelegate();
    final future = computation(state);
    return CancelableFuture._internal(state, future);
  }

  void rebindState(CancelState state) {
    _state.state = state;
  }

  void cancel() {
    _state.cancel();
  }
}
