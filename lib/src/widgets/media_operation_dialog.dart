import 'dart:io';

import 'package:flutter/material.dart';
import 'package:north/private_gallery.dart';
import 'package:provider/provider.dart';

import 'future_queue.dart';
import 'gallery_model.dart';
import 'thumbnail_grid.dart';
import 'thumbnail_tile.dart';

class CopyMediaDialog extends StatelessWidget {
  final List<Media> medias;

  CopyMediaDialog({@required this.medias});

  @override
  Widget build(BuildContext context) {
    return _MediaOperationDialog(
        medias: medias, operation: _MediaOperation.copy);
  }
}

class MoveMediaDialog extends StatelessWidget {
  final List<Media> medias;

  MoveMediaDialog({@required this.medias});

  @override
  Widget build(BuildContext context) {
    return _MediaOperationDialog(
        medias: medias, operation: _MediaOperation.move);
  }
}

enum _MediaOperation { copy, move }

class _MediaOperationDialog extends StatefulWidget {
  final List<Media> medias;
  final _MediaOperation operation;

  _MediaOperationDialog({@required this.medias, @required this.operation});

  @override
  _MediaOperationDialogState createState() => _MediaOperationDialogState();
}

class _MediaOperationDialogState extends State<_MediaOperationDialog> {
  FutureQueue<File> thumbnailLoaderQueue;
  Future<List<Album>> futureAlbums;
  var destinationAlbum = '';

  @override
  void initState() {
    super.initState();

    thumbnailLoaderQueue = FutureQueue();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final gallery = context.read<GalleryModel>();
    futureAlbums = gallery.getAllAlbums();
    thumbnailLoaderQueue.clear();
  }

  @override
  void dispose() {
    thumbnailLoaderQueue.dispose();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _thumbnailGrid(BuildContext context) {
    return FutureBuilder(
      future: futureAlbums,
      builder: (_, AsyncSnapshot<List<Album>> snapshot) {
        if (snapshot.hasError) {
          throw snapshot.error;
        }

        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        return ThumbnailGrid(
          builder: (_, ix) => _thumbnailTile(context, snapshot.data[ix]),
          itemCount: snapshot.data.length,
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        );
      },
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
      onTap: () async {
        _setDestinationAlbum(album.name);
        await _runOperation(context);
      },
    );
  }

  void _setDestinationAlbum(String albumName) {
    setState(() => destinationAlbum = albumName);
  }

  Future<void> _runOperation(BuildContext context) async {
    final ids = widget.medias.map((m) => m.id).toList();
    final gallery = context.read<GalleryModel>();
    switch (widget.operation) {
      case _MediaOperation.copy:
        await gallery.copyMedias(ids, destinationAlbum);
        break;
      case _MediaOperation.move:
        await gallery.moveMedias(ids, destinationAlbum);
        break;
      default:
        throw StateError('Unhandled operation ${widget.operation}.');
    }

    Navigator.pop(context);
  }

  Widget _operationProgressDialog(BuildContext context) {
    var operationName = '';
    switch (widget.operation) {
      case _MediaOperation.copy:
        operationName = 'Copying';
        break;
      case _MediaOperation.move:
        operationName = 'Moving';
        break;
      default:
        throw StateError('Unhandled operation ${widget.operation}.');
    }

    return AlertDialog(
      title: Text('$operationName media'),
      content: Column(
        children: [
          LinearProgressIndicator(),
          Text(
              '$operationName ${widget.medias.length} media to $destinationAlbum'),
        ],
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
