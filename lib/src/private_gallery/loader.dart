import 'dart:io';

import 'cancelable_future.dart';
import 'media_store.dart';
import 'uuid.dart';
import 'thumbnail_store.dart';

class ThumbnailLoader {
  final Uuid _id;
  final List<int> _salt;
  final ThumbnailStore _store;

  ThumbnailLoader(this._id, this._salt, this._store);

  Future<File> load() async {
    return _store.get(_id, _salt);
  }
}

class MediaLoader {
  final Uuid _id;
  final List<int> _salt;
  final MediaStore _store;

  MediaLoader(this._id, this._salt, this._store);

  CancelableFuture<File> load() {
    return _store.get(_id, _salt);
  }
}
