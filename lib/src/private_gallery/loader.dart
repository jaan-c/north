import 'dart:io';

import 'cancelable_future.dart';
import 'media_store.dart';
import 'uuid.dart';
import 'thumbnail_store.dart';

/// A handle for loading a thumbnail [File] from [ThumbnailStore].
class ThumbnailLoader {
  final Uuid _id;
  final ThumbnailStore _store;

  ThumbnailLoader(this._id, this._store);

  Future<File> load() async {
    return _store.get(_id);
  }
}

/// A handle for loading a media [File] from [MediaStore].
class MediaLoader {
  final Uuid _id;
  final MediaStore _store;

  MediaLoader(this._id, this._store);

  CancelableFuture<File> load() {
    return _store.get(_id);
  }
}
