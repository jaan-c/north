import 'package:async/async.dart';

class CancelledException implements Exception {
  @override
  String toString() => '${(CancelledException)}';
}

/// An object passed to [CancelableFuture] computation to signal cancellation.
abstract class CancelState {
  /// Throws [CancelledException] if [cancel] is called.
  void checkIsCancelled();

  /// Causes the next call to [checkIsCancelled] to throw [CancelledException].
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

/// A [Future] that can be signalled to cancel.
///
/// Takes a [computation] that must frequently call
/// [CancelState.checkIsCancelled] whenever possible.
class CancelableFuture<T> extends DelegatingFuture<T> {
  final _CancelStateDelegate _state;

  CancelableFuture._internal(this._state, Future<T> future) : super(future);

  factory CancelableFuture(CancelableComputation<T> computation) {
    final state = _CancelStateDelegate();
    final future = computation(state);
    return CancelableFuture._internal(state, future);
  }

  /// Override the state consulted by this with a wrapping [CancelableFuture]'s
  /// state. This way cancelation from the outer [CancelableFuture] propagates
  /// to this.
  CancelableFuture<T> rebindState(CancelState state) {
    _state.state = state;
    return this;
  }

  /// Signal [computation] to cancel.
  ///
  /// This causes the next call to [CancelState.checkIsCancelled] inside
  /// [computation] to throw [CancelledException].
  void cancel() {
    _state.cancel();
  }
}
