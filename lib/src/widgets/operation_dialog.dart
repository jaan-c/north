import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:quiver/iterables.dart';
import 'package:provider/provider.dart';

import 'future_queue.dart';
import 'gallery_model.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

class CopyDialog extends StatelessWidget {
  final List<Media> medias;

  CopyDialog({@required this.medias});

  @override
  Widget build(BuildContext context) {
    return _OperationDialog(medias: medias, operation: _Operation.copy);
  }
}

class MoveDialog extends StatelessWidget {
  final List<Media> medias;

  MoveDialog({@required this.medias});

  @override
  Widget build(BuildContext context) {
    return _OperationDialog(medias: medias, operation: _Operation.move);
  }
}

enum _Operation { copy, move }

class _OperationDialog extends StatefulWidget {
  final List<Media> medias;
  final _Operation operation;

  _OperationDialog({@required this.medias, @required this.operation});

  @override
  _OperationDialogState createState() => _OperationDialogState();
}

class _OperationDialogState extends State<_OperationDialog> {
  FutureQueue<File> thumbnailLoaderQueue;
  FutureQueue<void> operationQueue;

  var destinationAlbum = '';
  var progress = 0.0;

  @override
  void initState() {
    super.initState();

    thumbnailLoaderQueue = FutureQueue();
    operationQueue = FutureQueue();
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
      content: _thumbnailGrid(context),
      actions: [
        TextButton(
          child: Text('CANCEL'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _thumbnailGrid(BuildContext context) {
    final albums = context
        .select<GalleryModel, List<Album>>((gallery) => gallery.allAlbums);

    return ThumbnailGrid(
      builder: (_, ix) => _thumbnailTile(context, albums[ix]),
      itemCount: albums.length,
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
    );
  }

  Widget _thumbnailTile(BuildContext context, Album album) {
    return ThumbnailTile(
      name: album.name,
      count: album.mediaCount,
      loader: () => thumbnailLoaderQueue.add(
          () => context.read<GalleryModel>().loadAlbumThumbnail(album.name)),
      mode: ThumbnailTileMode.normal,
      borderRadius: BorderRadius.circular(24),
      onTap: () => _pickDestinationAlbum(context, album.name),
    );
  }

  void _pickDestinationAlbum(BuildContext context, String albumName) {
    setState(() => destinationAlbum = albumName);
    _runOperation(context);
  }

  Future<void> _runOperation(BuildContext context) async {
    for (final media in enumerate(widget.medias)) {
      switch (widget.operation) {
        case _Operation.copy:
          await operationQueue.add(() => context
              .read<GalleryModel>()
              .copyMedia(media.value.id, destinationAlbum));
          break;
        case _Operation.move:
          await operationQueue.add(() => context
              .read<GalleryModel>()
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
