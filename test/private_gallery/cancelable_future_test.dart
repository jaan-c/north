import 'package:flutter_test/flutter_test.dart';
import 'package:north/src/private_gallery/cancelable_future.dart';

void main() {
  final throwsCancelledException = throwsA(isInstanceOf<CancelledException>());

  test(
      '''CancelableFuture.cancel triggers CancelState.checkIsCancelled to throw 
      CancelledException.''', () async {
    final cancelableFuture = CancelableFuture(infinity);
    cancelableFuture.cancel();
    await expectLater(cancelableFuture, throwsCancelledException);
  });

  test(
      'CancelableFuture can wrap another CancelableFuture by overriding its state.',
      () async {
    final inner = CancelableFuture(infinity);
    final wrapper = CancelableFuture((state) async {
      inner.rebindState(state);
      return inner;
    });
    wrapper.cancel();

    await expectLater(wrapper, throwsCancelledException);
  });
}

Future<void> infinity(CancelState state) async {
  while (true) {
    state.checkIsCancelled();
    await Future.delayed(Duration(milliseconds: 100));
  }
}
