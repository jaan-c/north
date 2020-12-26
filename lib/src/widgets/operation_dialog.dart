import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:quiver/iterables.dart';

import 'async_queue.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

class CopyDialog extends StatelessWidget {
  final PrivateGallery gallery;
  final List<Media> medias;

  CopyDialog({@required this.gallery, @required this.medias});

  @override
  Widget build(BuildContext context) {
    return _OperationDialog(
        gallery: gallery, medias: medias, operation: _Operation.copy);
  }
}

class MoveDialog extends StatelessWidget {
  final PrivateGallery gallery;
  final List<Media> medias;

  MoveDialog({@required this.gallery, @required this.medias});

  @override
  Widget build(BuildContext context) {
    return _OperationDialog(
        gallery: gallery, medias: medias, operation: _Operation.move);
  }
}

enum _Operation { copy, move }

class _OperationDialog extends StatefulWidget {
  final PrivateGallery gallery;
  final List<Media> medias;
  final _Operation operation;

  _OperationDialog(
      {@required this.gallery,
      @required this.medias,
      @required this.operation});

  @override
  _OperationDialogState createState() => _OperationDialogState();
}

class _OperationDialogState extends State<_OperationDialog> {
  AsyncQueue<File> thumbnailLoaderQueue;
  Future<List<Album>> futureAlbums;
  AsyncQueue<void> operationQueue;

  var destinationAlbum = '';
  var progress = 0.0;

  @override
  void initState() {
    super.initState();

    futureAlbums = widget.gallery.getAllAlbums();
    thumbnailLoaderQueue = AsyncQueue();
    operationQueue = AsyncQueue();
  }

  @override
  void dispose() {
    thumbnailLoaderQueue.dispose();
    operationQueue.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (destinationAlbum.isEmpty) {
      return _albumPickerDialog(context);
    } else {
      return _operationProgressDialog(context);
    }
  }

  Widget _albumPickerDialog(BuildContext context) {
    return AlertDialog(
      title: Text('Select album'),
      content: _thumbnailGrid(),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _thumbnailGrid() {
    return FutureBuilder(
      future: futureAlbums,
      builder: (_, AsyncSnapshot<List<Album>> snapshot) {
        if (snapshot.hasError) {
          throw StateError('Failed to load albums: ${snapshot.hasError}');
        }

        if (snapshot.hasData) {
          return ThumbnailGrid(
            builder: (_, ix) => _thumbnailTile(snapshot.data[ix]),
            itemCount: snapshot.data.length,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Widget _thumbnailTile(Album album) {
    return ThumbnailTile(
      name: album.name,
      count: album.mediaCount,
      loader: () => thumbnailLoaderQueue
          .add(() => widget.gallery.loadAlbumThumbnail(album.name)),
      mode: ThumbnailTileMode.normal,
      borderRadius: BorderRadius.circular(24),
      onTap: () => _pickDestinationAlbum(album.name),
    );
  }

  void _pickDestinationAlbum(String albumName) {
    setState(() => destinationAlbum = albumName);
    _runOperation();
  }

  Future<void> _runOperation() async {
    for (final media in enumerate(widget.medias)) {
      switch (widget.operation) {
        case _Operation.copy:
          await operationQueue.add(() => widget.gallery
              .copyMedia(media.value.id, destinationAlbum, Uuid.generate()));
          break;
        case _Operation.move:
          await operationQueue.add(() => widget.gallery
              .moveMediaToAlbum(media.value.id, destinationAlbum));
          break;
        default:
          throw StateError('Unhandled operation ${widget.operation}.');
      }

      setState(() => progress = (media.index + 1) / widget.medias.length);
    }
  }

  Widget _operationProgressDialog(BuildContext context) {
    if (progress >= 1.0) {
      Future.delayed(Duration.zero, () => Navigator.pop(context));
    }

    var operationName = '';
    switch (widget.operation) {
      case _Operation.copy:
        operationName = 'Copying';
        break;
      case _Operation.move:
        operationName = 'Moving';
        break;
      default:
        throw StateError('Unhandled operation ${widget.operation}.');
    }

    return AlertDialog(
      title: Text('$operationName media'),
      content: Column(
        children: [
          LinearProgressIndicator(value: progress),
          Text(
              '$operationName ${widget.medias.length} media to $destinationAlbum'),
        ],
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      actions: [
        TextButton(
          child: Text('STOP'),
          onPressed: () {
            operationQueue.clear();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
