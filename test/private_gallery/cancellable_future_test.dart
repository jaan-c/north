import 'package:flutter_test/flutter_test.dart';
import 'package:north/src/private_gallery/cancellable_future.dart';

void main() {
  final throwsCancelledException = throwsA(isInstanceOf<CancelledException>());

  test(
      '''CancellableFuture.cancel triggers CancelState.checkIsCancelled to throw 
      CancelledException.''', () async {
    final cancellableFuture = CancellableFuture(infinity);
    cancellableFuture.cancel();
    await expectLater(cancellableFuture, throwsCancelledException);
  });

  test(
      'CancellableFuture can wrap another CancellableFuture by overriding its state.',
      () async {
    final inner = CancellableFuture(infinity);
    final wrapper = CancellableFuture((state) async {
      return inner.rebindState(state);
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
