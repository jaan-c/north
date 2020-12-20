import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:quiver/iterables.dart';

abstract class OperationQueueController implements ChangeNotifier {
  double get progress;
  bool get isDone;
  void start();
  void cancel();
}

class CopyQueueController
    with ChangeNotifier
    implements OperationQueueController {
  final PrivateGallery gallery;
  final List<Media> medias;
  final String destinationAlbum;

  CancellableFuture<void> _copyOperation;

  var _progress = 0.0;
  @override
  double get progress => _progress;

  var _isDone = false;
  @override
  bool get isDone => _isDone;

  CopyQueueController(
      {@required this.gallery,
      @required this.medias,
      @required this.destinationAlbum});

  @override
  void start() {
    _copyOperation = CancellableFuture(_startCopying);
  }

  Future<void> _startCopying(CancelState state) async {
    for (final media in enumerate(medias)) {
      await gallery.copyMedia(
          media.value.id, destinationAlbum, Uuid.generate());

      _progress = media.index / medias.length;
      notifyListeners();
    }

    _isDone = true;
    notifyListeners();
  }

  @override
  void cancel() {
    if (_copyOperation != null) {
      _copyOperation.cancel();
    } else {
      throw StateError('Cancelling copy that has not started yet.');
    }
  }

  @override
  void dispose() {
    if (!isDone) {
      _copyOperation.cancel();
    }
    super.dispose();
  }
}

class MoveQueueController
    with ChangeNotifier
    implements OperationQueueController {
  final PrivateGallery gallery;
  final List<Media> medias;
  final String destinationAlbum;

  CancellableFuture<void> _moveOperation;

  var _progress = 0.0;
  @override
  double get progress => _progress;

  var _isDone = false;
  @override
  bool get isDone => _isDone;

  MoveQueueController(
      {@required this.gallery,
      @required this.medias,
      @required this.destinationAlbum});

  @override
  void start() {
    _moveOperation = CancellableFuture(_startMoving);
  }

  Future<void> _startMoving(CancelState state) async {
    for (final media in enumerate(medias)) {
      await gallery.moveMediaToAlbum(media.value.id, destinationAlbum);

      _progress = media.index / medias.length;
      notifyListeners();
    }

    _isDone = true;
    notifyListeners();
  }

  @override
  void cancel() {
    if (_moveOperation != null) {
      _moveOperation.cancel();
    } else {
      throw StateError('Cancelling move that has not started yet.');
    }
  }

  @override
  void dispose() {
    if (!isDone) {
      _moveOperation.cancel();
    }
    super.dispose();
  }
}
